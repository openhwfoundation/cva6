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
Access to the per-target configuration of `config/target/<target>/`.

A target directory describes the hardware configuration under test and
is the single source of truth for it:

- `testbench_cfg.yml`   testbench flavour (`hier`: obi/axi)
- `isa.yml`             `march`/`mabi` the software is built for
- `link.ld`             linker script
- `spike.yaml`          Spike parameters of the tandem reference model
- `Flist.cva6`          RTL filelist
- `rtl_cfg_pkg.sv`      configuration package the RTL is built from
- `Flist.cva6_fpga`     RTL filelist of the FPGA top level
- `expected_values.yml` KPI baselines (gates, <test>_cycle, fpga_luts...)

A recipe states what it needs ("the hierarchy of this target") rather
than where it is stored, and a missing or malformed file produces one
actionable environment error instead of a raw traceback.

Every function takes the RecipeReport of the calling recipe and reports
a missing file through `report.error_exit(..., env=True)`: a target
configuration that cannot be read is a setup problem, not a test
failure, and the recipe must not carry on with a half-resolved
configuration.
"""

from pathlib import Path
import yaml

from flows.utils.autocompletion import Cva6Hier
from flows.utils.rtl_config import parse_rtl_cfg

# Names derived from the testbench flavour, kept next to the flavour
# itself rather than repeated in every recipe needing them. The two are
# used by disjoint sets of recipes, which is why they are separate
# helpers and neither is recorded by read_config_or_exit_testbench_cfg():
#
# - TOP_ELABORATE: top module wrapping the core, elaborated by the tools
#   that read the RTL standalone.
#       dc-shell-synth, spyglass-design-read, spyglass-run
#
# - DUT_HIER: path of the core instance *inside the UVM testbench*, used
#   to scope an SDF annotation (`-sdf` of the simulators) onto the
#   design under test. Only meaningful for a gate-level elaboration.
#       vcs/questa/xcelium-uvm-comp (gate modes only)
#
# Synthesis always closes on the same top module, so TOP_SYNTHESIS is a
# constant rather than a per-flavour entry.
TOP_SYNTHESIS = "cva6_top"

_TOP_ELABORATE = {
    Cva6Hier.obi: "cva6_example_obi",
    Cva6Hier.axi: "cva6_example_axi",
}

_DUT_HIER = {
    Cva6Hier.obi: (
        "uvmt_cva6_tb.cva6_dut_wrap.cva6_tb_wrapper_i.cva6_only_pipeline.i_cva6"
    ),
    Cva6Hier.axi: "uvmt_cva6_tb.cva6_dut_wrap.cva6_tb_wrapper_i.cva6.i_cva6",
}

# Both tables must cover the whole enum: the lookups below then cannot
# fail, so they need no report and no error path. Adding a flavour to
# Cva6Hier without its derived names breaks the import, at the first
# cook.py invocation, instead of failing inside a recipe.
assert set(_TOP_ELABORATE) == set(Cva6Hier), "missing TOP_ELABORATE entry"
assert set(_DUT_HIER) == set(Cva6Hier), "missing DUT_HIER entry"


def top_elaborate(cva6_hier):
    """
    Return the top module elaborated for a testbench flavour.

    Total over Cva6Hier (see the assertions above), so this cannot fail:
    the flavour has already been validated by
    read_config_or_exit_testbench_cfg(), which is the only way a recipe
    obtains one.
    """
    return _TOP_ELABORATE[cva6_hier]


def dut_hier(cva6_hier):
    """
    Return the path of the core instance inside the UVM testbench.

    Total over Cva6Hier, like top_elaborate(): cannot fail.
    """
    return _DUT_HIER[cva6_hier]


def target_dir(target, repo_dir=None):
    "Return the configuration directory of `target`"
    repo_dir = Path(repo_dir) if repo_dir else Path.cwd()
    return repo_dir / "config" / "target" / target


# ==========================================================
# Reading the target configuration
# ==========================================================
#
# Two families, told apart by their name (see flows/CONTRIBUTING.md):
#
# - `read_config_or_exit_*` aborts the recipe when the file or the key it
#   needs is missing: the recipe cannot do its job without it, so it stops
#   with an actionable message naming the file to add, and its report is
#   written before exiting.
#
# - `read_config_*` never aborts: what it returns is optional, an absent
#   value yields None (or {}) and the caller skips whatever depended on
#   it. Used for the KPI baselines, so a target without golden numbers
#   stays usable.


def _load_target_yaml(target, filename, report, or_exit):
    """
    Read a YAML file of the target configuration directory.

    Args:
        or_exit: when True, a missing/unreadable file aborts the recipe;
                 when False it yields {} and only warns.

    Returns the parsed content (a dict), or {} when absent and not or_exit.
    """
    path = target_dir(target) / filename
    if not path.exists():
        if or_exit:
            report.error_exit(
                f"Missing {path}\n"
                f"  Every target of config/target/ needs it: copy it from "
                f"another target and adapt it.",
                env=True,
            )
        return {}
    try:
        with path.open("r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except (OSError, yaml.YAMLError) as e:
        if or_exit:
            report.error_exit(f"Could not read {path}: {e}", env=True)
        report.warning(f"Could not read {path}: {e}")
        return {}


def read_config_or_exit_testbench_cfg(target, report, record=True):
    """
    Return the testbench hierarchy flavour of `target` as a Cva6Hier.

    The flavour comes from `testbench_cfg.yml`, not from a command line
    option: it is a property of the target, so the caller cannot
    contradict the design it elaborates.

    Args:
        record: also record the value in the report context and print it
                as the "Testbench parameters" table (the usual case)
    """
    path = target_dir(target) / "testbench_cfg.yml"
    cfg = _load_target_yaml(target, "testbench_cfg.yml", report, or_exit=True)
    if "hier" not in cfg:
        report.error_exit(f"No 'hier' key in {path}", env=True)
    try:
        cva6_hier = Cva6Hier(cfg["hier"])
    except ValueError:
        report.error_exit(
            f"Unknown hier {cfg['hier']!r} in {path}, "
            f"expected one of {[h.value for h in Cva6Hier]}",
            env=True,
        )
    if record:
        report.add_context({"cva6_hier": cva6_hier.value}, table="Testbench parameters")
    return cva6_hier


def read_config_or_exit_isa(target, report, march=None, mabi=None):
    """
    Resolve the (march, mabi) pair the software must be built with.

    Values given by the caller win; the ones left to None are taken from
    the `isa.yml` of the target, which is only read when something is
    actually missing: a fully explicit call needs no target configuration
    at all.

    Returns the (march, mabi) tuple.
    """
    if march is not None and mabi is not None:
        return march, mabi
    isa = _load_target_yaml(target, "isa.yml", report, or_exit=True)
    path = target_dir(target) / "isa.yml"
    for key, value in (("march", march), ("mabi", mabi)):
        if value is None and key not in isa:
            report.error_exit(f"No '{key}' key in {path}", env=True)
    return march or isa["march"], mabi or isa["mabi"]


def read_config_expected_values(target, report):
    """
    Return the KPI baselines of `target` (`expected_values.yml`), or {}.

    Optional by design: a target without baselines is reported by the
    recipes as a skipped check, never as a failure, so a new target does
    not have to carry golden numbers to be usable.
    """
    return _load_target_yaml(target, "expected_values.yml", report, or_exit=False)


def read_config_expected_value(target, key, report):
    """
    Return one KPI baseline of `target`, or None when unavailable.

    A missing file and a missing key are both reported as a warning and
    yield None: the caller then skips the check instead of failing on the
    baseline itself.
    """
    expected = read_config_expected_values(target, report)
    path = target_dir(target) / "expected_values.yml"
    if not expected:
        report.warning(f"{path} not found, skipping {key} check")
        return None
    if key not in expected:
        report.warning(f"Key '{key}' missing in {path}, skipping check")
        return None
    return expected[key]


# ==========================================================
# RTL filelist
# ==========================================================


def flist_substitutions(target, repo_dir=None):
    """
    Return the (placeholder, value) pairs used inside a CVA6 filelist.

    A filelist is written with the placeholders the Makefile flow exports;
    expanding them is what lets `read_config_or_exit_flist` follow the
    `-F` includes and hand absolute paths to the tools.

    Paths are POSIX: they end up in TCL scripts (dc_shell, fm_shell)
    where a backslash is an escape character.
    """
    repo_dir = Path(repo_dir) if repo_dir else Path.cwd()
    return [
        ("${TARGET_CFG}", target),
        ("${CVA6_REPO_DIR}", repo_dir.as_posix()),
        ("${HPDCACHE_DIR}", (repo_dir / "core/cache_subsystem/hpdcache").as_posix()),
    ]


def read_config_or_exit_flist(target, report, filename="Flist.cva6", repo_dir=None):
    """
    Return the RTL source files of `target`, in filelist order.

    Reads `config/target/<target>/<filename>`, expands the placeholders
    of `flist_substitutions()` and follows the `-F` includes recursively.
    Comments, blank lines and `+incdir+` entries are dropped, so what is
    returned is only source files: each caller then formats them the way
    its tool expects (an `analyze` command for dc_shell/fm_shell, a plain
    path for verible).

    A missing filelist (the target one or an included one) aborts the
    recipe: the file list is the design itself, there is nothing to do
    without it.
    """

    def parse(flist_path, patterns, collected, seen):
        flist_path = Path(flist_path)
        if not flist_path.exists():
            report.error_exit(f"Flist not found: {flist_path}", env=True)

        # An include cycle would otherwise recurse until the stack blows
        resolved = flist_path.resolve()
        if resolved in seen:
            report.warning(f"Flist already included, skipping: {flist_path}")
            return collected
        seen.add(resolved)

        try:
            text = flist_path.read_text(encoding="utf-8")
        except OSError as e:
            report.error_exit(f"Could not read {flist_path}: {e}", env=True)

        # Expand environment variables to be able to follow include Flist
        for search, replace in patterns:
            text = text.replace(search, replace)

        for line in text.splitlines():
            l = line.strip()
            if not l or l.startswith("//"):
                continue
            if l.startswith("+incdir+"):
                continue
            if l.startswith("-F"):
                parse(l[2:].strip(), patterns, collected, seen)
                continue
            collected.append(l)

        return collected

    path = target_dir(target, repo_dir) / filename
    return parse(path, flist_substitutions(target, repo_dir), [], set())


# ==========================================================
# RTL configuration package
# ==========================================================


def read_config_or_exit_rtl_cfg(target, report, repo_dir=None):
    """
    Return the resolved parameters of `config/target/<target>/rtl_cfg_pkg.sv`.

    The values the RTL is actually built with, as a name -> value dict
    (`{"XLEN": 32, "RVC": True, ...}`), `localparam` references resolved.
    See `flows/utils/rtl_config.py` for the parsing, and for why it does not
    reuse the one of `util/user_config.py`.

    A configuration package that cannot be read stops the recipe: it
    describes the design under test, so there is nothing to document or
    generate without it.
    """
    repo_dir = Path(repo_dir) if repo_dir else Path.cwd()
    path = target_dir(target, repo_dir) / "rtl_cfg_pkg.sv"
    if not path.exists():
        report.error_exit(
            f"Missing {path}\n"
            f"  Every target of config/target/ needs it: it is the "
            f"configuration package the RTL is built from.",
            env=True,
        )
    try:
        config = parse_rtl_cfg(path)
    except OSError as e:
        report.error_exit(f"Could not read {path}: {e}", env=True)
    if not config:
        report.error_exit(f"No parameter found in {path}", env=True)
    return config


def read_config_or_exit_doc(target, report):
    """
    Return the documentation header fields of `config/target/<target>/doc.yml`.

    Who is responsible for the documentation of a target, and under which
    licence it is published. The generated `.adoc` and `.rst` carry it, so
    a reader of a generated file knows who to address.

    Keys, all optional but for `authors`:

        copyright  the copyright line
        license    the licence name
        spdx       the SPDX identifier
        url        where to obtain the licence
        authors    who is responsible, one entry per line of the header

    A missing file stops the recipe rather than falling back to a default:
    the header names an owner, and a wrong owner is worse than an absent
    document.
    """
    path = target_dir(target) / "doc.yml"
    cfg = _load_target_yaml(target, "doc.yml", report, or_exit=True)
    authors = cfg.get("authors")
    if not authors:
        report.error_exit(
            f"No 'authors' key in {path}\n"
            f"  The generated documentation names who is responsible for "
            f"it: list at least one person or organisation.",
            env=True,
        )
    if isinstance(authors, str):
        report.error_exit(f"'authors' of {path} must be a list, not a string", env=True)
    return cfg
