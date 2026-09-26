# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Shared machinery of the documentation build.

Both modes of the `docs-build` recipe of `flows/recipes/` use it: the
AsciiDoctor run per manual (`_render_manual` and friends), and the
`--readthedoc` mode that puts the rendered manuals next to their pages so
ReadTheDocs can build them with Sphinx. The recipe itself only parses the
command line and reports.
"""

import re
import shutil
import tempfile
from pathlib import Path

from flows.utils.manifest import write_manifest
from flows.utils.run_cmd import run_cmd
from flows.utils.target_config import (
    read_config_or_exit_doc,
    read_config_or_exit_rtl_cfg,
)

# Extensions the CVA6 specifications may test but that no CVA6
# configuration implements: the RISC-V manuals expect every attribute to
# be defined, so they are emitted as false rather than left out.
DEFAULT_PARAMS = {
    "RVE": False,
    "RVQ": False,
    "RVZabha": False,
    "RVZacas": False,
    "RVZawrs": False,
    "RVZcmop": False,
    "RVZfa": False,
    "RVZfbf-RZvfbf": False,
    "RVZfh": False,
    "RVZfinx": False,
    "RVZicbo": False,
    "RVZicfilp": False,
    "RVZifencei": False,
    "RVZihintntl": False,
    "RVZihintpause": False,
    "RVZilsd": False,
    "RVZimop": False,
    "RVZk": False,
    "RVZpm": False,
    "RVZsmcdeleg": False,
    "RVZsmcntrpmf": False,
    "RVZsmcsrind-RVZsscsrind": False,
    "RVZsmctr": False,
    "RVZsmdbltrp": False,
    "RVZsmepmp": False,
    "RVZsmmpm": False,
    "RVZsmrnmi": False,
    "RVZsmstateen": False,
    "RVZsscofpmf": False,
    "RVZssdbltrp": False,
    "RVZsstc": False,
    "RVZtso": False,
    "RVZvk": False,
    "SV": "SV0",
}

# Modules whose IO ports are documented, relative to the repository root.
DOCUMENTED_MODULES = [
    "core/cva6.sv",
    "core/cva6_pipeline.sv",
    "core/frontend/frontend.sv",
    "core/frontend/bht.sv",
    "core/frontend/btb.sv",
    "core/frontend/ras.sv",
    "core/frontend/instr_queue.sv",
    "core/frontend/instr_scan.sv",
    "core/instr_realign.sv",
    "core/id_stage.sv",
    "core/issue_stage.sv",
    "core/ex_stage.sv",
    "core/commit_stage.sv",
    "core/controller.sv",
    "core/csr_regfile.sv",
    "core/decoder.sv",
    "core/compressed_decoder.sv",
    "core/scoreboard.sv",
    "core/issue_read_operands.sv",
    "core/alu.sv",
    "core/branch_unit.sv",
    "core/csr_buffer.sv",
    "core/mult.sv",
    "core/multiplier.sv",
    "core/serdiv.sv",
    "core/load_store_unit.sv",
    "core/load_unit.sv",
    "core/store_unit.sv",
    "core/lsu_bypass.sv",
    "core/cvxif_fu.sv",
    "core/cache_subsystem/cva6_hpdcache_subsystem.sv",
]

# Declaration of the user configuration structure, whose fields are the
# documented parameters and whose comments are their description.
USER_CFG_PKG = "core/include/config_pkg.sv"

# Default of each header field, used for the keys a `doc.yml` leaves out.
# Only `authors` has none: naming who is responsible for the documentation
# of a target is the point of the file.
DEFAULT_HEADER = {
    "copyright": "Copyright 2024 Thales DIS France SAS",
    "license": 'Licensed under the Solderpad Hardware License, Version 2.1 (the "License");',
    "spdx": "Apache-2.0 WITH SHL-2.1",
    "url": "https://solderpad.org/licenses/",
}

# Comment syntax of the generated formats: what opens the block, what
# prefixes a line, what closes it. reStructuredText has no closing marker,
# its comment being an indented block under `..`.
_COMMENT_SYNTAX = {
    "rst": ("..", "   ", None),
    "adoc": ("////", "   ", "////"),
}


def render_header(doc_cfg, syntax):
    """
    Return the licence and ownership header of a generated file.

    Args:
        doc_cfg: the `doc.yml` of the target, missing keys taken from
                 `DEFAULT_HEADER`
        syntax: "rst" or "adoc", the comment form of the generated file

    The authors are listed one per line, so an organisation and the people
    it delegates to can both appear.
    """
    open_marker, prefix, close_marker = _COMMENT_SYNTAX[syntax]
    field = {**DEFAULT_HEADER, **(doc_cfg or {})}

    lines = [f"{open_marker}\n"]
    for key in ("copyright", "license"):
        lines.append(f"{prefix}{field[key]}\n")
    lines.append(
        f"{prefix}you may not use this file except in compliance with the License.\n"
    )
    lines.append(f"{prefix}SPDX-License-Identifier: {field['spdx']}\n")
    lines.append(f"{prefix}You may obtain a copy of the License at {field['url']}\n")
    lines.append("\n")
    for author in field.get("authors") or []:
        lines.append(f"{prefix}{author}\n")
    if close_marker:
        lines.append(f"{close_marker}\n")
    lines.append("\n")
    return "".join(lines)


# Field of the user configuration structure, and the comment describing it
_FIELD_RE = re.compile(r"^ *(.*) (\S*);$")
_COMMENT_RE = re.compile(r"^ *// (.*)$")

# `input`/`output` port of a module, and the `// <description> - <net>`
# comment above it
_PORT_RE = re.compile(r"^ +(in|out)put +(\S*(?: +.* *|)) (\S*)$")
_PORT_DOC_RE = re.compile(r"^ +// (.*) - (\S*)$")

UNDOCUMENTED = "TO_BE_COMPLETED"


class Parameter:
    "A parameter of the user configuration structure"

    def __init__(self, datatype, description, value):
        self.datatype = datatype
        self.description = description
        self.value = value


class PortIO:
    "An IO port of a documented module"

    # A record: one attribute per column of the generated table
    # pylint: disable-next=too-many-arguments,too-many-positional-arguments
    def __init__(self, name, direction, data_type, description, connexion):
        self.name = name
        self.direction = direction
        self.data_type = data_type
        self.description = description
        self.connexion = connexion


def read_parameters(repo_dir, rtl_cfg):
    """
    Return the documented parameters of the user configuration structure.

    The names, types and descriptions come from the declaration of
    `cva6_user_cfg_t` in `config_pkg.sv`, the values from the resolved
    configuration package of the target (`rtl_cfg`, as read by
    `target_config.read_config_or_exit_rtl_cfg`).

    A parameter declared but absent from the configuration keeps
    `TO_BE_COMPLETED` as its value rather than failing the generation: the
    two files drift apart when a parameter is added to one only, and a
    missing value in a table is more useful than no documentation at all.
    """
    parameters = {}
    path = Path(repo_dir) / USER_CFG_PKG
    description = UNDOCUMENTED
    in_struct = False

    for line in path.read_text(encoding="utf-8").splitlines():
        if "typedef struct packed" in line:
            in_struct = True
        if "cva6_user_cfg_t" in line:
            break
        if not in_struct:
            continue
        comment = _COMMENT_RE.match(line)
        if comment:
            description = comment.group(1)
            continue
        field = _FIELD_RE.match(line)
        if field:
            parameters[field.group(2)] = Parameter(
                field.group(1), description, rtl_cfg.get(field.group(2), UNDOCUMENTED)
            )
            description = UNDOCUMENTED

    return parameters


def write_config_adoc(out_file, target, parameters):
    """
    Write the AsciiDoctor attributes of a configuration.

    This is what makes the RISC-V specifications configuration aware: they
    test those attributes to include or exclude a section, e.g.
    `ifeval::[{RVS} == true]`.
    """
    out_file = Path(out_file)
    out_file.parent.mkdir(parents=True, exist_ok=True)

    # A boolean is lowercased to match what the manuals compare it to.
    def attribute(name, value):
        return f":{name}: {str(value).lower() if isinstance(value, bool) else value}\n"

    lines = [f":ohg-config: {target.upper()}\n"]
    for name, value in DEFAULT_PARAMS.items():
        lines.append(attribute(name, value))
    for name, parameter in parameters.items():
        lines.append(attribute(name, parameter.value))
    out_file.write_text("".join(lines), encoding="utf-8")


def write_parameters_adoc(out_file, target, parameters, doc_cfg):
    "Write the parameter table of a configuration"
    out_file = Path(out_file)
    out_file.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        render_header(doc_cfg, "adoc"),
        f"[[{target}_PARAMETERS]]\n\n",
        f".{target} parameter configuration\n",
        "|===\n",
        "|Name | description | description\n\n",
    ]
    for name, parameter in parameters.items():
        lines.append(f"|{name} | {parameter.description} | {parameter.value}\n")
    lines.append("|===\n")
    out_file.write_text("".join(lines), encoding="utf-8")


def write_user_cfg_rst(out_file, parameters, doc_cfg):
    "Write the reference table of the user configuration structure"
    out_file = Path(out_file)
    out_file.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        render_header(doc_cfg, "rst"),
        ".. _cva6_user_cfg_doc:\n\n",
        ".. list-table:: ``cva6_user_cfg_t`` parameters\n",
        "   :header-rows: 1\n\n",
        "   * - Name\n",
        "     - Type\n",
        "     - Description\n",
    ]
    for name, parameter in parameters.items():
        lines.append("\n")
        lines.append(f"   * - ``{name}``\n")
        lines.append(f"     - ``{parameter.datatype.strip()}``\n")
        lines.append(f"     - {parameter.description}\n")
    out_file.write_text("".join(lines), encoding="utf-8")


def read_ports(module_file, blacklist):
    """
    Return the IO ports of a module, and the ones tied to a constant.

    A port whose name or whose connected net is in `blacklist` is not an
    interface of this configuration: it is tied to a constant value, so it
    is reported apart rather than documented as a port.

    Returns `(ports, comments)`, `comments` being `[reason, text]` pairs
    grouped by reason.
    """
    ports = []
    comments = []
    description, connexion = "none", "none"

    for line in Path(module_file).read_text(encoding="utf-8").splitlines():
        doc = _PORT_DOC_RE.match(line)
        if doc:
            description, connexion = doc.group(1), doc.group(2)
            continue
        port = _PORT_RE.match(line)
        if not port:
            continue
        direction, data_type, name = port.group(1), port.group(2), port.group(3)
        name = name.replace(",", "")
        data_type = data_type.replace(" ", "")

        tied = blacklist.get(connexion) or blacklist.get(name)
        if tied:
            reason, value = tied
            text = f"``{name}`` {direction}put is tied to {value}"
            for comment in comments:
                if comment[0] == reason:
                    comment[1] += f"\n|   {text}"
                    break
            else:
                comments.append([reason, text])
        else:
            ports.append(PortIO(name, direction, data_type, description, connexion))
        description, connexion = "none", "none"

    return ports, comments


def write_ports_adoc(out_dir, target, module, ports, comments, doc_cfg):
    "Write the IO port table of a module"
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / f"port_{module}.adoc"

    lines = [
        render_header(doc_cfg, "adoc"),
        f"[[_CVA6_{module}_ports]]\n\n",
        f".*{module} module* IO ports\n",
        "|===\n",
        "|Signal | IO | Description | connexion | Type\n\n",
    ]
    for port in ports:
        lines.append(
            f"|`{port.name}` | {port.direction} | {port.description} "
            f"| {port.connexion} | {port.data_type}\n\n"
        )
    lines.append("|===\n")

    if comments:
        lines.append(
            f"Due to {target.upper()} configuration, some ports are tied to a "
            f"static value. These ports do not appear in the above table, they "
            f"are listed below\n\n"
        )
        for reason, text in comments:
            # The port table is AsciiDoctor, where `` and | are markup
            reason = reason.replace("``", "`").replace("|", "*")
            text = text.replace("``", "`").replace("|", "*")
            lines.append(f"{reason},::\n*   {text}\n")
    lines.append("\n")

    out_file.write_text("".join(lines), encoding="utf-8")
    return out_file


# Ports a configuration wires to a constant: they exist in the RTL but
# carry no signal, so the documentation lists them apart from the real
# ones, with the parameter that explains why.
#
# `None` as a parameter means always tied. `expect` is the value the
# parameter must hold for the group to apply: `False` for the extensions
# that remove their ports when absent, a string for the ones compared to
# a literal.
#
# A group carrying a hardcoded value is compared against that value
# instead of the configuration: the parameter it names is not in the RTL
# configuration package yet.
# fmt: off
TIED_PORTS = [
    # always
    (None, None, None, {
        "0": [
            "flush_bp_i", "hwpf_base_set_i", "hwpf_base_i", "hwpf_base_o",
            "hwpf_param_set_i", "hwpf_param_i", "hwpf_param_o", "hwpf_throttle_set_i",
            "hwpf_throttle_i", "hwpf_throttle_o", "hwpf_status_o", "dcache_cmo_req_i",
        ],
        "1": ["dtlb_hit_i"],
        "open": ["dcache_cmo_resp_o"],
    }),
    ("PipelineOnly", True, None, {
        "0": [
            "icache_enable_o", "icache_flush_o", "dcache_enable_o", "dcache_flush_o",
            "dcache_flush_ack_i", "fetch_req_o", "fetch_rsp_i", "load_req_o",
            "load_rsp_i", "dcache_wbuffer_empty_i", "dcache_wbuffer_not_ni_i",
        ],
    }),
    ("RVZCMT", False, None, {
        "0": ["obi_zcmt_req_o", "obi_zcmt_rsp_i"],
    }),
    ("IsRVFI", "0", "0", {
        "0": ["RVFI"],
    }),
    ("DebugEn", False, None, {
        "0": [
            "set_debug_pc_o", "set_debug_pc_i", "debug_mode_o", "debug_mode_i",
            "debug_req_i", "single_step_o", "single_step_i",
        ],
    }),
    ("RVH", False, None, {
        "0": [
            "v_i", "v_o", "vfs_o", "vfs_i", "hfence_vvma_o", "hfence_gvma_o",
            "flush_tlb_vvma_i", "flush_tlb_gvma_i", "flush_tlb_vvma_o",
            "flush_tlb_gvma_o", "en_g_translation_o", "enable_g_translation_i",
            "en_ld_st_g_translation_o", "en_ld_st_g_translation_i", "ld_st_v_o",
            "ld_st_v_i", "csr_hs_ld_st_inst_i", "csr_hs_ld_st_inst_o", "vs_sum_i",
            "vs_sum_o", "vmxr_o", "vmxr_i", "vsatp_ppn_o", "vsatp_ppn_i", "vs_asid_o",
            "vs_asid_i", "hgatp_ppn_o", "hgatp_ppn_i", "vmid_o", "vmid_i", "vtw_o",
            "vtw_i", "hu_o", "hu_i", "ld_st_v_i", "tinst_i", "tinst_o",
            "csr_hs_ld_st_inst_o", "exception_gpaddr_i", "exception_tinst_i",
            "exception_gva_i", "hs_ld_st_inst_o", "hlvx_inst_o", "hfence_vvma_i",
            "hfence_gvma_i", "vmid_to_be_flushed_i", "gpaddr_to_be_flushed_i",
        ],
    }),
    ("RVV", False, None, {
        "0": ["vs_i", "vs_o"],
    }),
    ("RVS", False, None, {
        "0": [
            "en_translation_o", "enable_translation_o", "enable_translation_i",
            "en_ld_st_translation_o", "en_ld_st_translation_i", "sum_o", "sum_i",
            "satp_ppn_o", "satp_ppn_i", "vaddr_to_be_flushed_o",
            "vaddr_to_be_flushed_i", "asid_to_be_flushed_o", "asid_to_be_flushed_i",
            "mxr_o", "mxr_i", "asid_o", "asid_i", "sfence_vma_o", "sfence_vma_i",
        ],
    }),
    ("EnableAccelerator", "0", "0", {
        "0": ["ACC_DISPATCHER"],
    }),
    ("RVF", "0", "0", {
        "0": [
            "fs_o", "fs_i", "frm_o", "frm_i", "fpu_valid_o", "fpu_ready_o",
            "fpu_ready_i", "fpu_fmt_o", "fpu_rm_o", "fpu_valid_i", "fpu_fmt_i",
            "fpu_rm_i", "fpu_frm_i", "fpu_prec_i", "fpu_trans_id_o", "fpu_result_o",
            "fpu_exception_o", "csr_write_fflags_i", "fflags_o", "csr_write_fflags_o",
            "fprec_o", "dirty_fp_state_i", "dirty_fp_state_o", "we_fpr_i",
        ],
    }),
    ("RVA", False, None, {
        "0": [
            "amo_req_o", "amo_resp_i", "amo_valid_commit_o", "amo_valid_commit_i",
            "obi_amo_req_o", "obi_amo_rsp_i",
        ],
    }),
    ("PRIV", "MachineOnly", "MachineOnly", {
        "MAchineMode": ["ld_st_priv_lvl_o", "ld_st_priv_lvl_i"],
        "MachineMode": ["priv_lvl_o", "priv_lvl_i"],
        "0": ["tvm_o", "tvm_i", "tw_o", "tw_i", "tsr_o", "tsr_i"],
    }),
    ("PerfCounterEn", "0", "0", {
        "0": ["PERF_COUNTERS"],
    }),
    ("FenceEn", "0", "0", {
        "0": ["fence_i_o", "fence_i_i", "fence_o", "fence_i"],
    }),
    ("MMUPresent", "0", "0", {
        "0": [
            "flush_tlb_i", "flush_tlb_o", "dtlb_ppn_i", "obi_mmu_ptw_req_o",
            "obi_mmu_ptw_rsp_i",
        ],
    }),
]
# fmt: on


def define_blacklist(rtl_cfg):
    """
    Return `{port: [reason, tied value]}` for a resolved configuration.

    `rtl_cfg` is the name -> value dict of the configuration package.
    """
    black_list = {}
    for param, expect, hardcoded, ports in TIED_PORTS:
        if param is None:
            reason = "For any HW configuration"
        else:
            value = hardcoded if hardcoded is not None else rtl_cfg.get(param)
            if bool(value) != bool(expect) or (
                isinstance(expect, str) and value != expect
            ):
                continue
            reason = f"As {param} = {value}"
        for tied, names in ports.items():
            for name in names:
                black_list[name] = [reason, tied]
    return black_list


# AsciiDoctor extensions the RISC-V manuals require. The design manual
# needs none, see its entry below.
ASCIIDOCTOR_REQUIRES = [
    "asciidoctor-bibtex",
    "asciidoctor-diagram",
    "asciidoctor-lists",
    "asciidoctor-mathematical",
]


def asciidoctor_cmd(tool):
    """
    Command line prefix running an AsciiDoctor tool.

    The gems are the ones Ruby finds on its own, installed with `gem
    install` as the documentation of the flows describes.
    """
    return [tool]


def asciidoctor_found(tool):
    "Path of the tool; None when missing"
    return shutil.which(asciidoctor_cmd(tool)[0])


# Defects of the manuals themselves, reported by AsciiDoctor on every
# build and fixed upstream rather than here. Listed so a real failure is
# not lost among them; remove an entry once the submodule carries the fix.
KNOWN_CONTENT_DEFECTS = (
    # The conditional is closed in a file the manual does not include.
    "detected unterminated preprocessor conditional directive",
)

# The page of each manual, next to which the rendered document is placed
# in `--readthedoc` mode. Chapter directories of docs/ embed their
# manuals like `docs/05_cva6_apu` does for none (no `riscv/` or
# `design/` subdirectory).
READTHEDOC_CHAPTER_PAGE = {
    "priv": "riscv/priv.rst",
    "unpriv": "riscv/unpriv.rst",
    "design": "design/design.rst",
}

# A chapter whose target name has no `config/target/<name>` directory,
# because the configuration it documents is not one the RTL is built
# with: `cv64a6_mmu` moved under `deprecated_packages/` upstream. It is
# documented from the closest supported configuration instead.
READTHEDOC_CONFIGS = {
    "cv64a6_mmu": "cv64a6_imafdc_sv39_hpdcache_pmp_mmu_axi",
}

# Manuals a configuration can be documented by. `source` is where their
# `.adoc` live, `root` the document AsciiDoctor is given, and `output` the
# name the rendered document takes.
#
# The RISC-V manuals are assembled from the submodule with the CVA6
# overrides of `docs/riscv-isa/src` on top; the design manual is CVA6
# only.
MANUALS = {
    "priv": {
        "sources": [
            "riscv-isa/riscv-isa-manual/src",
            "riscv-isa/src",
            "common",
        ],
        "resources": "riscv-isa/riscv-isa-manual/docs-resources",
        "root": "riscv-privileged.adoc",
        "output": "priv-isa",
        "requires": ASCIIDOCTOR_REQUIRES,
    },
    "unpriv": {
        "sources": [
            "riscv-isa/riscv-isa-manual/src",
            "riscv-isa/src",
            "common",
        ],
        "resources": "riscv-isa/riscv-isa-manual/docs-resources",
        "root": "riscv-unprivileged.adoc",
        "output": "unpriv-isa",
        "requires": ASCIIDOCTOR_REQUIRES,
    },
    "design": {
        "sources": ["design/design-manual/source", "common"],
        "resources": "riscv-isa/riscv-isa-manual/docs-resources",
        "root": "design.adoc",
        "output": "design",
        # No extension: the design manual carries no bibliography, and
        # asciidoctor-bibtex fails outright without a bibtex file.
        "requires": [],
        # Warn rather than stay silent on a missing attribute, which is
        # how an undocumented parameter shows up.
        "options": ["-a", "attribute-missing=warn"],
        # The design manual is the one documenting the parameters and the
        # ports of the configuration, so it needs them generated.
        "needs_parameters": True,
        # It also includes the ISA and CSR tables of the target, which
        # `config/gen_from_riscv_config/` carries as generated and versioned
        # `.adoc`: copied in, not regenerated.
        "config_adoc": "config/gen_from_riscv_config/{target}",
        # Sources of one target laid over the common ones, its block
        # diagram among them, when docs/ has a directory for it.
        "target_sources": "0*_{target}/design/source",
        "target_diagram": {
            "name": "{target}_subsystems.png",
            "default": "CVA6_subsystems.png",
        },
    },
}

# Directories of docs/ left out of the copy Sphinx reads: the sources of
# the AsciiDoctor manuals, the manual submodule among them, and the output
# of an older build
SPHINX_SKIPPED_SOURCES = ["riscv-isa", "design", "_build", "build"]

# Sphinx reports one line per problem, as `<file>:<line>: WARNING: ...`
SPHINX_WARNING_RE = re.compile(r"WARNING:|ERROR:")


def _assemble_sources(work_dir, docs_dir, manual, report):
    """
    Copy the sources of a manual into its working directory.

    The later a source directory comes in the list, the higher its
    precedence, so the CVA6 overrides of `docs/riscv-isa/src` land on top
    of the ones the submodule carries.
    """
    src_dir = work_dir / "src"
    src_dir.mkdir(parents=True, exist_ok=True)

    for source in manual["sources"]:
        source_dir = docs_dir / source
        if not source_dir.is_dir():
            report.error_exit(f"Missing documentation sources: {source_dir}", env=True)
        for item in sorted(source_dir.iterdir()):
            target = src_dir / item.name
            if item.is_dir():
                shutil.copytree(item, target, dirs_exist_ok=True)
            else:
                shutil.copyfile(item, target)

    # The resources (fonts, themes, images) are read by the renderer
    # through a relative path, so they sit next to the sources.
    resources = docs_dir / manual["resources"]
    if not resources.is_dir():
        report.error_exit(
            f"Missing documentation resources: {resources}\n"
            f"  Run first: git submodule update --init --recursive",
            env=True,
        )
    shutil.copytree(resources, work_dir / "docs-resources", dirs_exist_ok=True)

    return src_dir


def _generate_adoc(src_dir, repo_dir, target, rtl_cfg, doc_cfg, manual, report):
    """
    Generate the `.adoc` a manual needs from the RTL configuration.

    `config.adoc` is what makes a specification configuration aware: the
    manuals test its attributes to include or exclude a section. The design
    manual also documents the parameters and the ports.
    """
    parameters = read_parameters(repo_dir, rtl_cfg)

    write_config_adoc(src_dir / "config.adoc", target, parameters)
    report.info(f"config.adoc written ({len(parameters)} parameters)")

    if not manual.get("needs_parameters"):
        return parameters

    config_adoc = manual.get("config_adoc")
    if config_adoc:
        source = repo_dir / config_adoc.format(target=target)
        if not source.is_dir():
            report.error_exit(
                f"Missing generated documentation of target '{target}': {source}\n"
                f"  It holds the ISA and CSR tables the design manual "
                f"includes, generated by "
                f"config/gen_from_riscv_config/scripts/riscv_config_gen.py.",
                env=True,
            )
        for item in sorted(source.iterdir()):
            destination = src_dir / item.name
            if item.is_dir():
                shutil.copytree(item, destination, dirs_exist_ok=True)
            else:
                shutil.copyfile(item, destination)
        report.info(f"ISA and CSR tables copied from {source.relative_to(repo_dir)}")

    pattern = manual.get("target_sources")
    if pattern:
        for overlay in sorted((repo_dir / "docs").glob(pattern.format(target=target))):
            shutil.copytree(overlay, src_dir, dirs_exist_ok=True)
            report.info(f"Target sources copied from {overlay.relative_to(repo_dir)}")

    # architecture.adoc draws the pipeline of the target by name: a target
    # without a diagram of its own gets the one of the generic CVA6
    diagram = manual.get("target_diagram")
    if diagram:
        images = src_dir / "images"
        own = images / diagram["name"].format(target=target.upper())
        if not own.exists():
            shutil.copyfile(images / diagram["default"], own)
            report.info(f"No block diagram of its own, {diagram['default']} used")

    write_parameters_adoc(src_dir / "parameters.adoc", target, parameters, doc_cfg)

    blacklist = define_blacklist(rtl_cfg)
    report.info(f"{len(blacklist)} port(s) tied to a constant by this configuration")

    n_ports = 0
    for module_file in DOCUMENTED_MODULES:
        path = repo_dir / module_file
        if not path.exists():
            report.warning(f"Documented module not found: {path}")
            continue
        ports, comments = read_ports(path, blacklist)
        write_ports_adoc(src_dir, target, path.stem, ports, comments, doc_cfg)
        n_ports += len(ports)
    report.info(f"{n_ports} port(s) documented over {len(DOCUMENTED_MODULES)} modules")

    return parameters


def _render_manual(
    out_dir,
    repo_dir,
    docs_dir,
    target,
    rtl_cfg,
    doc_cfg,
    name,
    fmt,
    renderers,
    strict,
    report,
):
    """
    Render one manual of one target into `out_dir`.

    The sources are assembled in a working directory under `out_dir`,
    the `.adoc` generated from the RTL configuration on top, then
    AsciiDoctor is run on the manual root document. The rendered file is
    moved next to the other outputs of the recipe; the working directory
    is left in place (dropped by `_drop_work_dir` once every manual of
    the target is rendered).

    Returns the produced document, or None when it failed.
    """
    spec = MANUALS[name]

    work_dir = out_dir / name
    src_dir = _assemble_sources(work_dir, docs_dir, spec, report)
    _generate_adoc(src_dir, repo_dir, target, rtl_cfg, doc_cfg, spec, report)

    root = src_dir / spec["root"]
    if not root.exists():
        report.error_exit(f"Missing manual root document: {root}", env=True)

    output = f"{spec['output']}-{target}.{fmt}"
    log_file = out_dir / f"{name}_{fmt}.log"
    cmd = asciidoctor_cmd(renderers[fmt]) + ["--trace"]
    cmd += ["-a", "compress"]
    cmd += ["-a", "mathematical-format=svg"]
    cmd += ["-a", "pdf-fontsdir=docs-resources/fonts"]
    cmd += ["-a", "pdf-theme=docs-resources/themes/riscv-pdf.yml"]
    # A diagram drawn twice in a manual is read back from the cache of
    # asciidoctor-diagram, which json 3 rejects (unknown keyword:
    # create_additions). The working directory is new on every build, so
    # the cache saves nothing.
    cmd += ["-a", "diagram-nocache-option"]
    cmd += ["-D", "out", "-o", output]
    cmd += spec.get("options", [])
    if strict:
        cmd += ["--failure-level=WARN"]
    for require in spec.get("requires", []):
        cmd += [f"--require={require}"]
    cmd += [str(root.relative_to(work_dir))]

    run_cmd(
        cmd=cmd,
        report=report,
        cwd=work_dir,
        # LANG: the manuals carry UTF-8 that a C locale mangles
        env={"LANG": "C.utf8"},
        error_patterns=["ERROR"],
        warning_patterns=["WARNING"],
        highlight_patterns=None,
        log_file=log_file,
        timeout=3600,
        check=False,
        capture_output=False,
    )

    # A document is produced whatever happens inside it: a diagram the
    # renderer could not generate leaves the error and the source of the
    # diagram in the page, and asciidoctor still exits 0. The log is what
    # says whether the manual is whole, so it is read in both cases.
    n_err, _ = report.analyze_log(
        log_file,
        name=f"{name}_{fmt}.log analysis",
        error_patterns=["ERROR"],
        env_patterns=[
            "command not found",
            "cannot load such file",
            "LoadError",
            "Failed to generate image",
        ],
        ignore_patterns=list(KNOWN_CONTENT_DEFECTS),
        fail_on_error=True,
    )

    produced = work_dir / "out" / output
    if produced.exists() and not n_err:
        final = out_dir / output
        shutil.move(str(produced), final)
        return final
    return None


def _drop_work_dir(out_dir, name, report):
    """
    Remove the working directory of one manual.

    It is its sources copied together with the generated `.adoc`:
    twenty megabytes per manual, of which nothing is read once the
    document is rendered. Dropped so the output directory holds the
    documents and the logs only, which is what a CI job archives.
    """
    work_dir = out_dir / name
    if not work_dir.is_dir():
        return
    try:
        shutil.rmtree(work_dir)
    except OSError as e:
        report.warning(f"Could not remove {work_dir}: {e}")


def _discover_readthedoc_chapters(docs_dir, report):
    """
    Return the chapters of docs/ that embed a manual.

    A chapter is a `0<NN>_<target>/` directory holding the page of at
    least one manual (`riscv/priv.rst`, `riscv/unpriv.rst`, or
    `design/design.rst`), as `docs/04_cv32a65x/` does for cv32a65x. Its
    target is the suffix of its name; the manuals it embeds are the ones
    whose page is there.

    Returns a list of `(directory, target, manuals)` tuples, one entry
    per chapter, in the numerical order of the chapter directories.
    """
    chapters = []
    for directory in sorted(docs_dir.glob("[0-9][0-9]_*")):
        if not directory.is_dir():
            continue
        target = directory.name.split("_", 1)[1]
        manuals = [
            name
            for name, page in READTHEDOC_CHAPTER_PAGE.items()
            if (directory / page).exists()
        ]
        if manuals:
            chapters.append((directory, target, manuals))
            report.info(
                f"{directory.name}: chapter of {target}, embeds "
                f"{', '.join(manuals)}"
            )

    if not chapters:
        report.error_exit(
            "No chapter of docs/ embeds a manual\n"
            "  Looked for the pages of the priv, unpriv and design manuals "
            "in the 0<NN>_<target>/ directories of docs/.",
            env=True,
        )
    return chapters


def _docs_build_readthedoc(repo_dir, docs_dir, strict, clean, report):
    """
    Prepare the documentation of every chapter of docs/ that embeds a
    manual for ReadTheDocs: each rendered
    `.html` is placed next to its page, and the user configuration
    reference regenerated in place, so `sphinx-build docs/` picks them up.
    Sphinx itself is left to ReadTheDocs, which runs it after this recipe.

    A chapter can document a configuration that is no longer supported:
    `cv64a6_mmu` has no `config/target/` directory of its own, and is
    documented from a supported one it is closest to, as `READTHEDOC_CONFIGS`
    maps it.
    """
    chapters = _discover_readthedoc_chapters(docs_dir, report)
    manuals = sorted({name for _, _, names in chapters for name in names})

    # AsciiDoctor only, once for every manual the chapters embed.
    renderers = _check_asciidoctor_tools(manuals, ["html"], report)

    out_dir = repo_dir / "build" / "readthedoc" / "docs"
    report.set_out_dir(out_dir)

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    if clean:
        try:
            if out_dir.exists():
                shutil.rmtree(out_dir)
                report.info(f"remove {out_dir}")
        except OSError as e:
            report.error_exit(f"Clean error : {e}", env=True)
    else:
        report.info(f"Skip cleaning {out_dir}")

    out_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {out_dir}")

    # ==========================================================
    # SPECIFICATIONS
    # ==========================================================
    results = report.metric("Specifications")
    documents = []
    for chapter_dir, target, chapter_manuals in chapters:
        config = READTHEDOC_CONFIGS.get(target, target)
        rtl_cfg = read_config_or_exit_rtl_cfg(config, report)
        report.add_context({"rtl_parameters": len(rtl_cfg)})
        doc_cfg = read_config_or_exit_doc(config, report)
        report.success(f"Documentation owned by: {', '.join(doc_cfg['authors'])}")

        for name in chapter_manuals:
            report.step(f"Build the {name} specification of {chapter_dir.name}")
            final = _render_manual(
                out_dir,
                repo_dir,
                docs_dir,
                target,
                rtl_cfg,
                doc_cfg,
                name,
                "html",
                renderers,
                strict,
                report,
            )
            if final is None:
                results.add_row(status="fail", manual=name, format="html", document="")
                continue
            results.add_row(
                status="pass", manual=name, format="html", document=final.name
            )
            documents.append(final)

            page = chapter_dir / READTHEDOC_CHAPTER_PAGE[name]
            destination = page.parent / final.name
            shutil.copyfile(final, destination)
            report.success(f"Placed next to its page: {destination}")

        # Regenerated for every chapter: the last one wins.
        write_user_cfg_rst(
            docs_dir / "01_cva6_user" / "user_cfg_doc.rst",
            read_parameters(repo_dir, rtl_cfg),
            doc_cfg,
        )
        report.info("docs/01_cva6_user/user_cfg_doc.rst regenerated for " f"{config}")

    for name in manuals:
        _drop_work_dir(out_dir, name, report)

    report.print_metric(results)
    if results.failed:
        report.error("Some specifications could not be built")
    else:
        report.success(f"{len(documents)} specification(s) built")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        out_dir,
        "docs-build",
        {
            "readthedoc": True,
            "chapters": [
                {"directory": d.name, "target": t, "manual": m} for d, t, m in chapters
            ],
            "strict": strict,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    generated = []
    for document in documents:
        report.info(f"> {document}")
        generated.append(str(document.relative_to(repo_dir)))

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")


def _check_asciidoctor_tools(manuals, formats, report):
    """
    Check AsciiDoctor and the gems the manuals need.

    Returns the renderers dict, the tool of each format.

    The tools are only asked for by the manuals declaring them, so a
    build of the design manual alone runs with plain AsciiDoctor: it
    needs no gem, and should not fail without one. The gems are loaded by
    the renderer at startup, from where Ruby looks rather than from the
    path, so a gem installed outside what `GEM_HOME` names is found by
    neither, and the render fails on `cannot load such file`. Checked by
    rendering a probe document, `--version` answering before it loads
    anything.
    """
    renderers = {"html": "asciidoctor", "pdf": "asciidoctor-pdf"}

    required = sorted(
        {gem for name in manuals for gem in MANUALS[name].get("requires", [])}
    )

    if manuals:
        for fmt in formats:
            tool = renderers[fmt]
            path = asciidoctor_found(tool)
            if path is None:
                report.error_exit(
                    f"{' '.join(asciidoctor_cmd(tool))}: Not found\n"
                    f"  The specifications are rendered by AsciiDoctor, "
                    f"installed with the gems of the Gemfile of the manuals\n"
                    f"  See flows/README.md#documentation-dependencies",
                    env=True,
                )
            report.success(f"{' '.join(asciidoctor_cmd(tool))}: {path}")

        # `run_cmd` with check=False: a failed load is the answer here, not
        # a failure of the pipeline, and what it returns is the output of the
        # tool, where asciidoctor prints `could not be loaded`.
        if required:
            with tempfile.TemporaryDirectory() as probe_dir:
                probe = Path(probe_dir) / "probe.adoc"
                probe.write_text("= Probe\n\ncontent\n", encoding="utf-8")
                for gem in required:
                    output = run_cmd(
                        cmd=asciidoctor_cmd(renderers["html"])
                        + [
                            f"--require={gem}",
                            "-o",
                            str(Path(probe_dir) / "probe.html"),
                            str(probe),
                        ],
                        report=report,
                        check=False,
                        capture_output=True,
                        log_file=None,
                        timeout=120,
                    )
                    if "could not be loaded" in output:
                        report.error_exit(
                            f"{gem}: not loadable by {renderers['html']}\n"
                            f"  A manual asked for needs it. Install the gems "
                            f"of the manuals:\n"
                            f"    gem install --user-install -g docs/riscv-isa"
                            f"/riscv-isa-manual/dependencies/Gemfile\n"
                            f"  See flows/README.md"
                            f"#documentation-dependencies",
                            env=True,
                        )
                    report.success(f"{gem}: loads")

    return renderers


def _check_prerequisites(docs_dir, target, manuals, formats, sphinx, report):
    """
    Check the tools and the configuration the build needs.

    Returns `(renderers, rtl_cfg, doc_cfg)`: the tool of each format, the
    RTL parameters of the target and the owner of its documentation.
    """
    report.step("Check prerequisites")

    if not docs_dir.is_dir():
        report.error_exit(f"Missing documentation directory {docs_dir}", env=True)

    renderers = _check_asciidoctor_tools(manuals, formats, report)

    if sphinx:
        sphinx_build = shutil.which("sphinx-build")
        if sphinx_build is None:
            report.error_exit(
                "sphinx-build: Not found\n"
                "  Install the documentation dependencies and put their entry "
                "points in the path:\n"
                "    pip3 install -r flows/requirements.txt\n"
                "  A virtual environment carries them in its bin/, activated "
                "by VENV_PATH of setenv.sh.",
                env=True,
            )
        report.success(f"sphinx-build: {sphinx_build}")

    # What the specifications are built for, and what the design manual
    # documents.
    rtl_cfg = read_config_or_exit_rtl_cfg(target, report)
    report.add_context({"rtl_parameters": len(rtl_cfg)})
    report.success(f"{len(rtl_cfg)} RTL parameter(s) read")

    # Who the generated documents name as responsible for them.
    doc_cfg = read_config_or_exit_doc(target, report)
    report.success(f"Documentation owned by: {', '.join(doc_cfg['authors'])}")

    report.success("Prerequisites OK")
    return renderers, rtl_cfg, doc_cfg
