# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

"""
RISC-V ISA String Manipulation Recipe

=== ISA STRING FORMAT ===
RISC-V ISA strings follow this format: rv{bitwidth}{single_letters}[_{multi_letter}]*

Examples:
    rv32imc              → 32-bit, I+M+C extensions
    rv64gc_zba_zbb       → 64-bit, G macro, Zba and Zbb extensions
    rv32imafd_zicsr      → 32-bit, I+M+A+F+D, Zicsr extension

=== WHY TWO CATEGORIES? ===
The distinction between single-letter and multi-letter extensions comes from RISC-V spec:

1. SINGLE-LETTER (historical, base ISA):
   - Format: Concatenated without separator (e.g., "imc")
   - Examples: I, M, A, F, D, C, Q, L, B, J, T, P, V, N, H
   - These are the original RISC-V base extensions

2. MULTI-LETTER (modern, named extensions):
   - Format: Separated by underscores (e.g., "_zicsr_zba")
   - Examples: Zicsr, Zifencei, Zba, Zbb, Zbs, Zcmt, etc.
   - These are newer, more specific extensions with descriptive names

3. MACRO EXTENSIONS:
   - 'G' = IMAFD_Zicsr_Zifencei (mixes both categories!)
   - This is why we can't unify the two: macros span both

If we unified them, we'd break compatibility:
    rv32_i_m_c_zicsr    ← INVALID (tools won't recognize this)
    rv32imc_zicsr       ← VALID (standard format)

=== EXTENSION DEPENDENCIES (as per RISC-V spec) ===
- D (double-precision float) requires F (single-precision float)
- Q (quad-precision float) requires D (and therefore F)
- V (vector) requires D (and therefore F)
- Zdinx requires Zfinx
- Zcb, Zcmp, Zcmt require Zca (or C)
- G is a shorthand for IMAFD + Zicsr + Zifencei
"""

import shutil
from pathlib import Path
from dataclasses import dataclass
from typing import List, Set
import typer
from flows.utils.recipe_report import RecipeReport
from flows.utils.autocompletion import autocompletion_target

app = typer.Typer()


# ==========================================================
# CONSTANTS
# ==========================================================

# ISA format separators (as per RISC-V spec)
SINGLE_LETTER_SEPARATOR = ""  # Extensions concatenated (rv32imc)
MULTI_LETTER_SEPARATOR = "_"  # Extensions separated (zicsr_zba)

# Canonical ordering of single-letter extensions (RISC-V spec)
CANONICAL_ORDER = [
    "i",
    "e",
    "g",
    "m",
    "a",
    "f",
    "d",
    "q",
    "l",
    "c",
    "b",
    "j",
    "t",
    "p",
    "v",
    "n",
    "h",
]

# Extension dependencies: key requires all values in the list
EXTENSION_DEPENDENCIES = {
    # Single-letter standard extensions
    "d": ["f"],  # Double requires float
    "q": ["d", "f"],  # Quad requires double and float
    "v": ["d", "f"],  # Vector requires double and float
    # Multi-letter extensions
    "zdinx": ["zfinx"],  # Double-in-integer-regs requires float-in-integer-regs
    "zqinx": ["zdinx", "zfinx"],  # Quad-in-integer-regs
    "zhinx": ["zfinx"],  # Half-precision-in-integer-regs
    # Code-size reduction (Zc*)
    "zcb": ["zca", "c"],  # Additional 16-bit encodings
    "zcmp": ["zca", "c"],  # Push/pop and double move
    "zcmt": ["zca", "c"],  # Table jump
    # Note: Zca is the base for all Zc* extensions
    # If 'c' (compressed) is present, it implies Zca functionality
}

# Extension macros: shorthand that expands to multiple extensions
# According to RISC-V spec: G = IMAFD_Zicsr_Zifencei
EXTENSION_MACROS = {
    "g": {
        "single": ["i", "m", "a", "f", "d"],  # Single-letter extensions
        "multi": ["zicsr", "zifencei"],  # Multi-letter extensions
    },
}


# ==========================================================
# HELPER FUNCTIONS
# ==========================================================


def _is_single_letter(ext: str) -> bool:
    """
    Check if extension is single-letter (historical format).

    Single-letter extensions are concatenated: rv32imc
    Multi-letter extensions are separated: _zicsr_zba
    """
    return len(ext) == 1


def _normalize_ext(ext: str) -> str:
    """Normalize extension name to lowercase for case-insensitive comparison."""
    return ext.lower()


def _ext_in_list(ext: str, ext_list: List[str]) -> bool:
    """Case-insensitive check if extension is in list."""
    return _normalize_ext(ext) in [_normalize_ext(e) for e in ext_list]


def _remove_duplicates(ext_list: List[str]) -> List[str]:
    """Remove duplicates from extension list while preserving order."""
    seen = set()
    unique = []
    for e in ext_list:
        e_norm = _normalize_ext(e)
        if e_norm not in seen:
            seen.add(e_norm)
            unique.append(e)
    return unique


# ==========================================================
# PARSED ISA DATA STRUCTURE
# ==========================================================


@dataclass
class ParsedISA:
    """
    Parsed RISC-V ISA string.

    RISC-V ISA format: rv{32|64}{single_letters}[_{multi_letter}]*
    - Single-letter extensions (I, M, A, F, D, C, etc.) are concatenated without separators
    - Multi-letter extensions (Zicsr, Zba, etc.) are separated by underscores

    Example: "rv32imc_zicsr_zba"
        prefix: "rv32"
        single: ["i", "m", "c"]
        multi: ["zicsr", "zba"]
    """

    prefix: str  # rv32, rv64, rv128
    single: List[str]  # Single-letter extensions (concatenated in output)
    multi: List[str]  # Multi-letter extensions (underscore-separated)

    def to_string(self) -> str:
        """
        Rebuild ISA string following RISC-V format.

        Returns:
            ISA string like "rv32imc_zicsr_zba"
        """
        base = self.prefix + SINGLE_LETTER_SEPARATOR.join(self.single)
        if self.multi:
            return (
                base + MULTI_LETTER_SEPARATOR + MULTI_LETTER_SEPARATOR.join(self.multi)
            )
        return base

    def has_extension(self, ext: str) -> bool:
        """
        Check if extension is present (handles 'g' macro expansion).

        Args:
            ext: Extension to check (e.g., 'f', 'zicsr')

        Returns:
            True if extension is present or implied by 'g' macro

        Example:
            >>> parsed = ParsedISA(prefix='rv32', single=['g', 'c'], multi=['zba'])
            >>> parsed.has_extension('f')
            True  # 'g' includes 'f'
        """
        ext_norm = _normalize_ext(ext)

        if _is_single_letter(ext):
            # Check in single-letter list
            if _ext_in_list(ext_norm, self.single):
                return True
            # Check if 'g' includes it (g = IMAFD)
            if (
                _ext_in_list("g", self.single)
                and ext_norm in EXTENSION_MACROS["g"]["single"]
            ):
                return True
            return False
        # Check in multi-letter list
        return _ext_in_list(ext_norm, self.multi)

    def add_to_single(self, ext: str):
        """Add single-letter extension if not present."""
        if not _ext_in_list(ext, self.single):
            self.single.append(_normalize_ext(ext))

    def add_to_multi(self, ext: str):
        """Add multi-letter extension if not present."""
        if not _ext_in_list(ext, self.multi):
            self.multi.append(_normalize_ext(ext))

    def remove_from_single(self, ext: str):
        """Remove single-letter extension."""
        self.single = [
            e for e in self.single if _normalize_ext(e) != _normalize_ext(ext)
        ]

    def remove_from_multi(self, ext: str):
        """Remove multi-letter extension."""
        self.multi = [e for e in self.multi if _normalize_ext(e) != _normalize_ext(ext)]

    def sort_single(self):
        """Sort single-letter extensions in canonical order (RISC-V spec)."""
        self.single.sort(
            key=lambda x: (
                CANONICAL_ORDER.index(_normalize_ext(x))
                if _normalize_ext(x) in CANONICAL_ORDER
                else 99
            )
        )

    def expand_g_macro(self):
        """
        Expand 'g' macro to all its components per RISC-V spec.

        According to RISC-V spec: G = IMAFD + Zicsr + Zifencei

        This method expands 'g' completely:
        - Single-letter: I, M, A, F, D
        - Multi-letter: Zicsr, Zifencei

        If user doesn't want Zicsr/Zifencei, they can remove them explicitly
        after expansion, just like any other extension.

        Example:
            rv64gc → rv64imafdc_zicsr_zifencei  (full spec-compliant expansion)

            Then if user wants: remove_extension(..., "zicsr")
        """
        if _ext_in_list("g", self.single):
            self.remove_from_single("g")

            # Add single-letter components
            g_single = EXTENSION_MACROS["g"]["single"]
            self.single.extend(g_single)
            self.single = _remove_duplicates(self.single)

            # Add multi-letter components (Zicsr, Zifencei)
            g_multi = EXTENSION_MACROS["g"]["multi"]
            for m_ext in g_multi:
                self.add_to_multi(m_ext)

    def compact_to_g_if_possible(self):
        """
        Compact to 'g' macro if ALL components are present.

        According to RISC-V spec: G = IMAFD + Zicsr + Zifencei

        To compact to 'g', we need:
        - Single-letter: I, M, A, F, D
        - Multi-letter: Zicsr, Zifencei

        If all are present, replace with 'g' and remove the components.
        """
        g_single = EXTENSION_MACROS["g"]["single"]
        g_multi = EXTENSION_MACROS["g"]["multi"]

        # Check if we have ALL components of 'g' (both single AND multi)
        has_all_single = all(_ext_in_list(e, self.single) for e in g_single)
        has_all_multi = all(_ext_in_list(e, self.multi) for e in g_multi)

        if has_all_single and has_all_multi:
            # Remove IMAFD and add 'g'
            for ext in g_single:
                self.remove_from_single(ext)
            self.add_to_single("g")

            # Remove Zicsr/Zifencei (now implied by 'g')
            for ext in g_multi:
                self.remove_from_multi(ext)


# ==========================================================
# ISA MANIPULATION UTILITIES
# ==========================================================


def get_all_dependencies(ext: str) -> Set[str]:
    """
    Get all transitive dependencies for an extension.

    Args:
        ext: Extension name (e.g., 'q', 'zdinx')

    Returns:
        Set of all required dependencies

    Example:
        >>> get_all_dependencies('q')
        {'d', 'f'}  # q requires d, d requires f
    """
    ext_lower = _normalize_ext(ext)
    deps = set()

    if ext_lower in EXTENSION_DEPENDENCIES:
        for dep in EXTENSION_DEPENDENCIES[ext_lower]:
            deps.add(dep)
            # Recursively get dependencies of dependencies
            deps.update(get_all_dependencies(dep))

    return deps


def get_dependent_extensions(ext: str, all_exts: List[str]) -> Set[str]:
    """
    Get all extensions that depend on the given extension.

    Args:
        ext: Extension to check dependencies for
        all_exts: List of all extensions to check against

    Returns:
        Set of extensions that depend on ext

    Example:
        >>> get_dependent_extensions('f', ['i', 'm', 'f', 'd', 'q'])
        {'d', 'q'}  # d and q both depend on f
    """
    ext_lower = _normalize_ext(ext)
    dependents = set()

    for other_ext in all_exts:
        other_lower = _normalize_ext(other_ext)
        if ext_lower in get_all_dependencies(other_lower):
            dependents.add(other_ext)

    return dependents


def parse_isa(isa_string: str) -> ParsedISA:
    """
    Parse RISC-V ISA string into structured format.

    Args:
        isa_string: RISC-V ISA string (e.g., "rv32imc_zicsr_zba")

    Returns:
        ParsedISA object with prefix, single-letter, and multi-letter extensions

    Raises:
        ValueError: If ISA string format is invalid

    Example:
        >>> parse_isa("rv32imc_zicsr_zba")
        ParsedISA(prefix='rv32', single=['i', 'm', 'c'], multi=['zicsr', 'zba'])
    """
    parts = isa_string.split(MULTI_LETTER_SEPARATOR)
    base = parts[0]
    multi = parts[1:] if len(parts) > 1 else []

    # Extract prefix and single-letter extensions
    # Check rv128 first (longest prefix)
    prefix_map = [
        ("rv128", 5),
        ("rv64", 4),
        ("rv32", 4),
    ]

    for prefix, offset in prefix_map:
        if base.startswith(prefix):
            single = list(base[offset:])
            return ParsedISA(prefix=prefix, single=single, multi=multi)

    raise ValueError(
        f"Invalid ISA string: {isa_string} (expected rv32*, rv64*, or rv128*)"
    )


def has_extension(isa_string: str, ext: str) -> bool:
    """
    Check if ISA has an extension (handles 'g' macro expansion).

    Args:
        isa_string: RISC-V ISA string
        ext: Extension to check

    Returns:
        True if extension is present or implied by 'g' macro

    Note: 'g' is a macro that expands to IMAFD + Zicsr + Zifencei

    Example:
        >>> has_extension("rv64gc_zba", "f")
        True  # 'g' includes 'f'
        >>> has_extension("rv32imc", "a")
        False
    """
    parsed = parse_isa(isa_string)
    return parsed.has_extension(ext)


def add_extension(isa_string: str, ext: str) -> str:
    """
    Add extension to ISA string if not already present.
    Automatically adds required dependencies and compacts to 'g' when possible.
    When adding 'g', removes redundant zicsr/zifencei.

    Args:
        isa_string: Input ISA string
        ext: Extension to add

    Returns:
        Modified ISA string

    Example:
        >>> add_extension("rv32imc_zicsr", "f")
        "rv32imfc_zicsr"
        >>> add_extension("rv32imc", "d")
        "rv32imfdc"  # Automatically adds 'f' (dependency of 'd')
        >>> add_extension("rv32imafd_zicsr_zifencei", "c")
        "rv32gc"  # Compacts to 'g', removes redundant zicsr/zifencei
    """
    # Check if already present
    if has_extension(isa_string, ext):
        return isa_string

    parsed = parse_isa(isa_string)
    ext_lower = _normalize_ext(ext)

    if _is_single_letter(ext):
        # Add single-letter extension
        # Add dependencies first
        deps = get_all_dependencies(ext_lower)
        for dep in deps:
            if not _ext_in_list(dep, parsed.single):
                parsed.add_to_single(dep)

        # Add the extension itself
        parsed.add_to_single(ext_lower)

        # Try to compact to 'g' if we have i+m+a+f+d
        parsed.compact_to_g_if_possible()

        # Sort in canonical order
        parsed.sort_single()
    else:
        # Add multi-letter extension
        # Add dependencies first
        deps = get_all_dependencies(ext_lower)
        for dep in deps:
            if not _ext_in_list(dep, parsed.multi) and not _ext_in_list(
                dep, parsed.single
            ):
                # Check if it's a single-letter or multi-letter dependency
                if _is_single_letter(dep):
                    parsed.add_to_single(dep)
                else:
                    parsed.add_to_multi(dep)

        parsed.add_to_multi(ext_lower)

    return parsed.to_string()


def add_extensions(isa_string: str, *exts: str) -> str:
    """
    Add multiple extensions to ISA string.

    Args:
        isa_string: Input ISA string
        *exts: Extensions to add

    Returns:
        Modified ISA string

    Example:
        >>> add_extensions("rv32imc", "f", "d", "zba")
        "rv32imfdc_zba"
        >>> add_extensions("rv32i", "m", "a", "f", "d")
        "rv32g"  # Compacts to 'g'
    """
    result = isa_string
    for ext in exts:
        result = add_extension(result, ext)
    return result


def remove_extension(isa_string: str, ext: str) -> str:
    """
    Remove extension from ISA string if present.
    Automatically removes dependent extensions and expands/re-compacts 'g' when needed.
    Note: 'i' is always kept as it's the base integer instruction set.

    When removing from 'g', the macro is first expanded to all its components
    (IMAFD + Zicsr + Zifencei), then the requested extension is removed.

    Args:
        isa_string: Input ISA string
        ext: Extension to remove

    Returns:
        Modified ISA string
    Example:
        >>> remove_extension("rv32imfc_zicsr", "f")
        "rv32imc_zicsr"  # Also removes 'd' if present (d depends on f)
        >>> remove_extension("rv64gc_zba", "f")
        "rv64imac_zicsr_zifencei_zba"  # Expands 'g', removes 'f'+'d'
        >>> remove_extension("rv64gc", "g")
        "rv64ic_zicsr_zifencei"  # Removes g (imafd), keeps c and multi-letter
    """
    parsed = parse_isa(isa_string)
    ext_lower = _normalize_ext(ext)

    if _is_single_letter(ext):
        # Single-letter extension
        # First, expand 'g' if present (to enable fine-grained removal)
        parsed.expand_g_macro()

        # Find all extensions that depend on this one
        all_exts = parsed.single + parsed.multi
        dependents = get_dependent_extensions(ext_lower, all_exts)

        # Remove the extension and all its dependents (but never remove 'i')
        extensions_to_remove = {ext_lower} | {_normalize_ext(d) for d in dependents}
        extensions_to_remove.discard("i")  # Never remove 'i'

        parsed.single = [
            e for e in parsed.single if _normalize_ext(e) not in extensions_to_remove
        ]
        parsed.multi = [
            e for e in parsed.multi if _normalize_ext(e) not in extensions_to_remove
        ]

        # Ensure 'i' is always present (base ISA)
        if not _ext_in_list("i", parsed.single):
            parsed.add_to_single("i")

        # Try to compact back to 'g' if we have exactly imafd
        if ext_lower != "g":
            parsed.compact_to_g_if_possible()

        # Sort in canonical order
        parsed.sort_single()
    else:
        # Multi-letter extension
        # Find and remove dependents
        all_exts = parsed.single + parsed.multi
        dependents = get_dependent_extensions(ext_lower, all_exts)

        extensions_to_remove = {ext_lower} | {_normalize_ext(d) for d in dependents}
        parsed.multi = [
            e for e in parsed.multi if _normalize_ext(e) not in extensions_to_remove
        ]
        parsed.single = [
            e for e in parsed.single if _normalize_ext(e) not in extensions_to_remove
        ]

    return parsed.to_string()


def remove_extensions(isa_string: str, *exts: str) -> str:
    """
    Remove multiple extensions from ISA string.
    Automatically handles 'g' expansion/compaction.

    Args:
        isa_string: Input ISA string
        *exts: Extensions to remove

    Returns:
        Modified ISA string

    Example:
        >>> remove_extensions("rv32imfdc_zicsr_zba", "f", "d", "zba")
        "rv32imc_zicsr"
        >>> remove_extensions("rv64gc_zba_zbb", "f", "d")
        "rv64imac_zba_zbb"  # Expands 'g', removes 'f' and 'd'
    """
    result = isa_string
    for ext in exts:
        result = remove_extension(result, ext)
    return result


# ==========================================================
# RECIPE - RISC-V ISA STRING MODIFICATION
# ==========================================================


@app.command()
def riscv_isa_modify(
    target: str = typer.Option(
        ...,
        "--target",
        "-t",
        help="CVA6 user configuration (for output directory isolation)",
        autocompletion=autocompletion_target,
    ),
    isa_string: str = typer.Option(
        ...,
        "--isa",
        "-i",
        help="Input RISC-V ISA string (e.g., rv32imc_zicsr or rv64gc)",
    ),
    add_ext: list[str] = typer.Option(
        [],
        "--add",
        "-a",
        help="Extensions to add if not present (can be specified multiple times)",
    ),
    remove_ext: list[str] = typer.Option(
        [],
        "--remove",
        "-r",
        help="Extensions to remove if present (can be specified multiple times)",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    RISC-V ISA string modification utility

    This recipe allows you to modify a RISC-V ISA string by adding or removing extensions.
    It automatically handles extension dependencies and G-macro expansion/compaction.

    Examples:
        # Add floating-point extensions
        ./cook.py riscv-isa-modify -t cv32a60x --isa rv32imc --add f --add d

        # Remove floating-point (also removes dependent extensions)
        ./cook.py riscv-isa-modify -t cv64a6_imafdc_sv39 --isa rv64gc --remove f

        # Add and remove extensions in one command
        ./cook.py riscv-isa-modify -t cv32a60x --isa rv32imc_zicsr --add f --add d --remove c
    """

    # Setup directory structure (per-target isolation)
    repo_dir = Path.cwd()
    output_dir = repo_dir / "build" / target / "riscv_isa_modify"
    env_file = output_dir / "modified_isa.yml"

    report = RecipeReport(
        "riscv-isa-modify",
        out_dir=output_dir,
        title="RISC-V ISA STRING MODIFICATION",
        context={
            "target": target,
            "isa_string": isa_string,
            "add_ext": add_ext,
            "remove_ext": remove_ext,
        },
        quiet=quiet,
    )

    # ==========================================================
    # VALIDATE INPUT
    # ==========================================================

    report.step("Validate input")

    # Check for conflicting extensions (present in both add and remove)
    add_set = set(_normalize_ext(ext) for ext in add_ext)
    remove_set = set(_normalize_ext(ext) for ext in remove_ext)
    conflicts = add_set & remove_set

    if conflicts:
        conflict_list = ", ".join(sorted(conflicts))
        report.error(
            f"Conflicting extensions found in both add and remove lists: {conflict_list}"
        )
        report.error_exit(
            "Each extension must be in either add or remove list, not both"
        )

    # Validate ISA string format
    try:
        parsed_original = parse_isa(isa_string)
        report.success(f"Input ISA string is valid: {isa_string}")
    except ValueError as e:
        report.error_exit(f"Invalid ISA string: {e}")

    # ==========================================================
    # PROCESS EXTENSIONS
    # ==========================================================

    report.step("Process extensions")

    result_isa = isa_string

    # Add extensions first (as specified in requirements)
    if add_ext:
        try:
            result_isa = add_extensions(result_isa, *add_ext)
            report.info(f"After adding extensions: {result_isa}")
        except Exception as e:
            report.error_exit(f"Error adding extensions: {e}")

    # Then remove extensions
    if remove_ext:
        try:
            result_isa = remove_extensions(result_isa, *remove_ext)
            report.info(f"After removing extensions: {result_isa}")
        except Exception as e:
            report.error_exit(f"Error removing extensions: {e}")

    # ==========================================================
    # DISPLAY RESULTS
    # ==========================================================

    report.step("Results")

    # Parse final ISA string to show details
    try:
        parsed_final = parse_isa(result_isa)

        # Build display strings
        original_single = "".join(parsed_original.single)
        original_multi = (
            ", ".join(parsed_original.multi) if parsed_original.multi else "None"
        )
        final_single = "".join(parsed_final.single)
        final_multi = ", ".join(parsed_final.multi) if parsed_final.multi else "None"

        report.param_table(
            {
                "Original ISA": isa_string,
                "Original prefix": parsed_original.prefix,
                "Original single-letter": original_single,
                "Original multi-letter": original_multi,
            },
            "Original ISA Details",
        )

        report.param_table(
            {
                "Modified ISA": result_isa,
                "Modified prefix": parsed_final.prefix,
                "Modified single-letter": final_single,
                "Modified multi-letter": final_multi,
            },
            "Modified ISA Details",
        )

        report.metric("Result", {"input_isa": isa_string, "modified_isa": result_isa})
        report.set_label(result_isa)

        report.success(f"Final ISA string: {result_isa}")

    except Exception as e:
        report.error(f"Error parsing final ISA string: {e}")

    # ==========================================================
    # EXPORT TO FILE (for GitLab CI)
    # ==========================================================

    report.step("Export to file")

    # Clean output directory
    try:
        if output_dir.exists():
            shutil.rmtree(output_dir)
            report.info(f"remove {output_dir}")
    except Exception as e:
        report.error_exit(f"Clean error: {e}", env=True)

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {output_dir}")

    # Write result to YAML file
    try:
        with env_file.open("w") as f:
            f.write("# Auto-generated by riscv-isa-modify recipe\n")
            f.write(f"modified_isa: {result_isa}\n")
            f.write(f"original_isa: {isa_string}\n")

        report.info(f"YAML file created: {env_file}")
        if not quiet:
            report.info(f"To use: grep modified_isa {env_file} | awk '{{print $2}}'")
    except Exception as e:
        report.error_exit(f"Error writing environment file: {e}", env=True)

    # ==========================================================
    # COMPLETION
    # ==========================================================

    report.end("Completed")
