# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Analysis of the spike tandem report (`tandem_report.yml`).

The testbench scoreboard (uvmc_rvfi_scoreboard_utils.sv, rvfi_gen_report)
writes this YAML file when the simulation is run with `+report_file=`.
The `SIMULATION PASSED` banner does not cover the tandem comparison: a
run with tandem mismatches still prints it. This module reads the file
back to give the comparison a blocking verdict.

Some ISA extensions are known to be incompatible with the Spike version
we currently use: the tandem comparison then reports spurious
mismatches. For those targets the test still runs with tandem enabled,
but the tandem verdict is downgraded to warnings and the PASS/FAIL
status falls back to the simulation status alone (banner/return code),
as when tandem is disabled. The report records `tandem_mismatch` in its
context so the HTML report can single out this kind of PASS.
"""

import yaml

# ISA features known to be incompatible with the Spike version we
# currently use for the tandem comparison: their presence in the target
# ISA makes the tandem verdict non-blocking (mismatches downgraded to
# warnings). Keys are extension names as they appear in the ISA string
# (the `g` shorthand is expanded before matching) or the `rv32`/`rv64`
# base; values document why. Extend this dict as new incompatibilities
# are identified.
SPIKE_TANDEM_BROKEN_EXTENSIONS = {
    "rv64": "64-bit configurations show spurious mismatches with our Spike version",
    "f": "floating-point state/CSR handling differs with our Spike version",
    "d": "floating-point state/CSR handling differs with our Spike version",
}


def _isa_extensions(isa):
    """
    Return the set of extension names of an ISA string.

    Minimal parsing for the compatibility check: the `rv32`/`rv64`
    base, the single letters of the base part (`rv64imac` -> i, m, a,
    c) with `g` expanded to its canonical set, then the
    underscore-separated multi-letter extensions (`_zba_zbb` -> zba,
    zbb).
    """
    isa = str(isa).lower().strip()
    base, _, tail = isa.partition("_")
    extensions = {base[:4]}  # rv32 / rv64
    for letter in base[4:]:
        if letter == "g":
            extensions.update("imafd")
            extensions.update(("zicsr", "zifencei"))
        else:
            extensions.add(letter)
    if tail:
        extensions.update(tail.split("_"))
    return extensions


def spike_broken_extensions(isa):
    """Sorted list of the extensions of `isa` known to break tandem."""
    return sorted(_isa_extensions(isa) & set(SPIKE_TANDEM_BROKEN_EXTENSIONS))


def _spike_isa(spike_param_file, report):
    """ISA string that Spike uses, read from the target spike.yaml."""
    try:
        with spike_param_file.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return str(data["spike_param_tree"]["isa"])
    except (OSError, yaml.YAMLError, KeyError, TypeError) as e:
        report.warning(f"Cannot read the ISA from {spike_param_file}: {e}")
        return ""


def _to_int(value):
    """
    Convert a tandem report scalar to int.

    The scoreboard writes counters with `$fdisplay("0x%4h", ...)`: PyYAML
    may load them as int (plain `0x1a2b`) or as str when `%4h` pads with
    spaces (`0x   0`). Returns None if the value cannot be converted.
    """
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        try:
            return int(value.replace(" ", ""), 16)
        except ValueError:
            return None
    return None


def check_tandem_verdict(tandem_report, spike_param_file, report):
    """
    Record the tandem verdict, downgraded if the ISA breaks Spike.

    Single entry point for the `*_uvm_run` recipes, to keep the tandem
    logic in one place. The ISA that Spike uses (from the target
    spike.yaml) is checked against SPIKE_TANDEM_BROKEN_EXTENSIONS:

    - no problematic extension: the tandem comparison is a blocking
      verdict (a mismatch fails the test), as usual;
    - problematic extension(s): tandem errors are recorded as warnings
      only, the test verdict falls back to the simulation status, and a
      detected mismatch is recorded as `tandem_mismatch` in the report
      context (rendered as an orange PASS in the HTML report).

    Only call this when the simulation was run with tandem enabled.
    """
    isa = _spike_isa(spike_param_file, report)
    broken = spike_broken_extensions(isa)
    if broken:
        reasons = "; ".join(f"{e}: {SPIKE_TANDEM_BROKEN_EXTENSIONS[e]}" for e in broken)
        report.warning(
            f"ISA '{isa}' contains extension(s) incompatible with the current "
            f"Spike tandem ({reasons}). Tandem mismatches are reported as "
            "warnings only; the test verdict is the simulation status alone."
        )
    mismatch = analyze_tandem_report(tandem_report, report, blocking=not broken)
    if broken and mismatch:
        report.add_context({"tandem_mismatch": True})


def analyze_tandem_report(tandem_report, report, blocking=True):
    """
    Read `tandem_report.yml` back and record the tandem verdict.

    Only call this when the simulation was run with tandem enabled.

    Args:
        tandem_report: Path of the tandem_report.yml written by the
            testbench scoreboard (via `+report_file=`)
        report: RecipeReport of the calling recipe. A mismatch or an
            exit_cause other than SUCCESS records an error (fail_kind:
            test); a missing/unreadable file records an error too, since
            the tandem verdict cannot be trusted without it.
        blocking: when False (ISA known to break Spike tandem, see
            check_tandem_verdict) tandem problems are recorded as
            warnings instead of errors and do not fail the recipe.

    Returns True if a tandem problem was detected (mismatch, bad exit
    cause/code, missing or unreadable report), False otherwise.
    """
    report.step("Analyze tandem report")
    problem = report.error if blocking else report.warning

    if not tandem_report.exists():
        problem(
            f"Tandem enabled but {tandem_report.name} was not produced: "
            "tandem comparison cannot be verified"
        )
        return True

    try:
        with tandem_report.open("r", encoding="utf-8", errors="replace") as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        problem(f"Cannot parse {tandem_report.name}: {e}")
        return True

    if not isinstance(data, dict):
        problem(f"Invalid tandem report format in {tandem_report}")
        return True

    exit_cause = str(data.get("exit_cause", "UNKNOWN")).strip()
    exit_code = _to_int(data.get("exit_code"))
    instr_count = _to_int(data.get("instr_count"))
    csrs_match_count = _to_int(data.get("csrs_match_count"))
    mismatches_count = _to_int(data.get("mismatches_count"))

    report.metric(
        "Tandem report",
        {
            "exit_cause": exit_cause,
            "exit_code": exit_code,
            "instr_count": instr_count,
            "csrs_match_count": csrs_match_count,
            "mismatches_count": mismatches_count,
        },
    )

    mismatch_description = str(data.get("mismatch_description", "")).strip()
    if mismatch_description:
        report.warning(f"Tandem mismatch description: {mismatch_description}")

    found = False
    if exit_cause != "SUCCESS":
        problem(f"Tandem exit cause: {exit_cause} (exit code: {exit_code})")
        found = True
    elif exit_code != 0:
        problem(f"Tandem exit code: {exit_code}")
        found = True

    if mismatches_count is None:
        problem(f"Tandem mismatches count missing in {tandem_report.name}")
        found = True
    elif mismatches_count > 0:
        problem(f"Tandem comparison: {mismatches_count} mismatch(es)")
        found = True
    elif not found:
        report.success(f"Tandem comparison OK ({instr_count} instructions compared)")

    return found
