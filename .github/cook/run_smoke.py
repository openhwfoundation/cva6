#!/usr/bin/env python3
# Copyright 2026 OpenHW Foundation
# SPDX-License-Identifier: Apache-2.0
"""Run the committed two-Hello smoke through Cook and validate its evidence.

Every Cook recipe leaves two files in its output directory, and the checks
below read nothing else from Cook:

- cook_report.yml: the verdict. `status` is `pass` or `fail`, `label` a
  short summary, `metrics` the tables the recipe printed.
- cook_manifest.yml: the recipe and the options it ran with, `recipe` and
  `options`.

The simulation log is read on top of them, as a second opinion that does
not depend on how Cook reached its verdict.
"""

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

import yaml

TARGET = "cv32a65x_axi"
TESTLIST = "verif/tests/testlist_verilator_testharness_smoke.yaml"
TESTS = ("hello-original_0", "hello-uart_0")
GREETING = "0: Hello World !"
BUILD = Path("build") / TARGET
RUNS = BUILD / "simulation" / "sim_rtl_verilator_testharness"
# testharness-run-testlist writes its table in a directory named after the
# simulator and the stem of the testlist.
BATCH = BUILD / "simulation" / f"testharness_verilator_{Path(TESTLIST).stem}"
MODEL = BUILD / "elab" / "sim_rtl_verilator_testharness"
REPORT = "cook_report.yml"
MANIFEST = "cook_manifest.yml"


def read_yaml(path):
    "Load a YAML file."
    with path.open(encoding="utf-8") as stream:
        return yaml.safe_load(stream)


def require_fields(data, expected, label):
    "Raise unless `data` is a mapping holding every item of `expected`."
    if not isinstance(data, dict):
        raise ValueError(f"Missing {label}")
    wrong = {k: data.get(k) for k, v in expected.items() if data.get(k) != v}
    if wrong:
        raise ValueError(f"Inconsistent {label}: {wrong}, expected {expected}")


def metric(report, name, label):
    "Return the rows of the table `name` of a Cook report."
    for table in report.get("metrics") or []:
        if isinstance(table, dict) and table.get("name") == name:
            return table.get("data") or []
    raise ValueError(f"No '{name}' table in the {label}")


def checked_report(directory, recipe, label):
    """
    Return the Cook report of a recipe after checking that it passed.

    `fail_kind` tells a failure of the environment (a tool missing, a
    prerequisite not built) from a failure of the design: worth reporting,
    the fix is not in the same place.
    """
    report = read_yaml(directory / REPORT)
    if not isinstance(report, dict):
        raise ValueError(f"Missing {label} in {directory}")
    if report.get("recipe") != recipe or report.get("status") != "pass":
        raise ValueError(
            f"{label}: recipe={report.get('recipe')!r} status={report.get('status')!r}"
            f" fail_kind={report.get('fail_kind')!r} label={report.get('label')!r}"
        )
    return report


def checked_run(directory, name):
    "Check one test run by verilator-testharness-run, and return its verdict."
    report = checked_report(directory, "verilator-testharness-run", f"{name} report")
    manifest = read_yaml(directory / MANIFEST)
    require_fields(
        manifest,
        {"recipe": "verilator-testharness-run"},
        f"{name} manifest",
    )
    require_fields(
        manifest.get("options"),
        {
            "target": TARGET,
            "test_name": name,
            "comp_mode": "rtl",
            "trace_mode": "notrace",
            "interactive_gui": False,
        },
        f"{name} manifest options",
    )

    # The verdict of the recipe, as it wrote it in the table of its steps.
    steps = metric(report, "Summary", f"{name} report")
    verdict = [row for row in steps if row.get("step") == f"Run {name}"]
    if len(verdict) != 1 or verdict[0].get("status") != "pass":
        raise ValueError(f"{name}: no passing 'Run {name}' step in the report")

    log = (directory / "testharness.log").read_text(encoding="utf-8")
    if "*** SUCCESS *** (tohost = 0)" not in log or any(
        marker in log
        for marker in (
            "*** FAILED ***",
            "SIMULATION FAILED",
            "[FAILED]",
            "UVM_ERROR",
            "UVM_FATAL",
        )
    ):
        raise ValueError(f"Missing successful termination or failure marker in {name}")
    # Only UART Hello promises visible text with this bare-metal runtime.
    if name == "hello-uart_0" and GREETING not in log:
        raise ValueError("UART Hello did not print the expected greeting")
    return verdict[0]["message"]


def checked_batch(root):
    "Check the report of testharness-run-testlist against the two runs."
    report = checked_report(root / BATCH, "testharness-run-testlist", "testlist report")
    if report.get("label") != f"{len(TESTS)}/{len(TESTS)} PASS":
        raise ValueError(f"Unexpected testlist label: {report.get('label')!r}")
    require_fields(
        report.get("context"),
        {
            "target": TARGET,
            "simulator": "verilator",
            "comp_mode": "rtl",
            "trace_mode": "notrace",
        },
        "testlist report context",
    )
    rows = metric(report, "Test results", "testlist report")
    expected = [
        {"status": "pass", "test": name, "report": str(root / RUNS / name)}
        for name in TESTS
    ]
    if rows != expected:
        raise ValueError(f"Testlist rows disagree with the two runs: {rows}")
    return report


def cook_commands():
    "Return the Cook commands of the smoke, as (stage, argv) in order."
    cook = [sys.executable, "cook.py"]
    run_options = ["-t", TARGET, "--trace-mode", "notrace", "--quiet"]
    return [
        (
            "compile-software",
            cook
            + [
                "sw-compile-testlist",
                "-t",
                TARGET,
                "-c",
                "github_actions_gcc",
                "-l",
                TESTLIST,
            ],
        ),
        (
            "compile-testharness",
            cook
            + [
                "verilator-testharness-comp",
                "-t",
                TARGET,
                "--trace-mode",
                "notrace",
                "--quiet",
            ],
        ),
        *[
            (name, cook + ["verilator-testharness-run", "-n", name] + run_options)
            for name in TESTS
        ],
        (
            "testlist",
            cook
            + ["testharness-run-testlist", "--simulator", "verilator", "-l", TESTLIST]
            + run_options,
        ),
    ]


def run_logged(command, *, cwd, env, log, timeout):
    "Run a command with its output in `log`; return (exit code, timed out)."
    with log.open("w", encoding="utf-8") as stream:
        try:
            done = subprocess.run(
                command,
                cwd=cwd,
                env=env,
                stdout=stream,
                stderr=subprocess.STDOUT,
                timeout=timeout,
                check=False,
            )
        except subprocess.TimeoutExpired:
            return None, True
    return done.returncode, False


def sha256(path):
    "Return the SHA-256 of a file."
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_summary(evidence, destination):
    "Append the result table to the GitHub step summary."
    lines = [
        f"## Two-Hello smoke: {evidence['status']}",
        "",
        f"- Actual checkout: `{evidence.get('source_revision', 'unavailable')}`",
        f"- Event head: `{evidence.get('event_head', 'unavailable')}`",
        "- Target: `cv32a65x_axi`; RTL-only, notrace, no ISS/tandem.",
        "",
        "| Execution | Original Hello: normal exit | UART Hello: normal exit + text |",
        "| --- | --- | --- |",
    ]
    for phase in ("single", "batch"):
        results = evidence["checks"][phase]
        lines.append(f"| {phase} | {results[TESTS[0]]} | {results[TESTS[1]]} |")
    lines += [
        "",
        f"Batch report consistency: **{evidence['report_check']}**.",
        "",
        "Original Hello output is not required. UART output is checked in the simulation log.",
        "This is an execution smoke, not a full ISA regression or an interrupt-handling test.",
    ]
    if "error" in evidence:
        lines += [
            "",
            f"Error: `{evidence['error']}`",
            "",
            "Details are in `ci-results/evidence.json`, the step logs, and the"
            " `cook_report.yml` of the failing recipe.",
        ]
    with destination.open("a", encoding="utf-8") as stream:
        stream.write("\n".join(lines) + "\n")


def save(root, output, directory, names):
    "Copy the Cook files of a recipe into the uploaded results."
    saved = output / directory.relative_to(BUILD)
    saved.mkdir(parents=True, exist_ok=True)
    for name in names:
        if (root / directory / name).exists():
            shutil.copy2(root / directory / name, saved / name)


def main():  # pylint: disable=too-many-locals,too-many-branches,too-many-statements
    "Run the smoke, write ci-results/evidence.json, and return the exit code."
    root = Path.cwd()
    output = root / "ci-results"
    output.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    evidence = {
        "schema_version": 2,
        "status": "FAIL",
        "target": TARGET,
        "testlist": TESTLIST,
        "validation_mode": "rtl-only",
        "reference_model": None,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "commands": [],
        "checks": {
            phase: dict.fromkeys(TESTS, "NOT CHECKED") for phase in ("single", "batch")
        },
        "report_check": "NOT CHECKED",
        "sha256": {},
    }
    rc = 1
    try:
        # A fresh hosted checkout must never accept previous build products.
        if (root / BUILD).exists():
            raise ValueError(
                "Use a fresh checkout without existing target build outputs"
            )
        evidence["source_revision"] = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], text=True, timeout=10
        ).strip()
        for key in ("event-head", "event-base"):
            path = output / f"{key}.txt"
            evidence[key.replace("-", "_")] = (
                path.read_text().strip() if path.exists() else ""
            )
        entries = read_yaml(root / TESTLIST)["testlist"]
        if [entry["test"] for entry in entries] != [
            "hello-original",
            "hello-uart",
        ] or any(
            # type() rather than isinstance(): `True` is an int too.
            # pylint: disable-next=unidiomatic-typecheck
            type(entry.get("iterations")) is not int or entry["iterations"] != 1
            for entry in entries
        ):
            raise ValueError(
                "Expected the committed two-entry Hello testlist with one iteration each"
            )
        for relative in (
            TESTLIST,
            "verif/tests/custom/hello_world/hello_world.c",
            "verif/tests/custom/hello_world/testharness_uart_hello_world.c",
        ):
            evidence["sha256"][relative] = sha256(root / relative)
        metadata = Path(env["CONFIG_DIR"]) / "environment.yml"
        environment = read_yaml(metadata)
        require_fields(
            environment,
            {"validation_mode": "rtl-only", "required_toolchain": "github_actions_gcc"},
            "tool environment",
        )
        evidence["environment"] = environment
        shutil.copy2(metadata, output / "toolchain-environment.yml")

        verdicts = {}
        for label, command in cook_commands():
            log = output / f"{label}.log"
            print("Running:", " ".join(command), flush=True)
            code, timed_out = run_logged(
                command, cwd=root, env=env, log=log, timeout=2100
            )
            evidence["commands"].append(
                {
                    "stage": label,
                    "argv": command,
                    "cwd": str(root),
                    "exit_code": code,
                    "timed_out": timed_out,
                    "log": log.name,
                }
            )
            if code != 0 or timed_out:
                if label in TESTS:
                    evidence["checks"]["single"][label] = "FAIL"
                raise ValueError(
                    f"{label} failed: exit={code}, timed_out={timed_out}; see {log.name}"
                )
            if label == "compile-testharness":
                checked_report(root / MODEL, "verilator-testharness-comp", label)
                save(root, output, MODEL, (REPORT, MANIFEST, "verilator.version"))
            if label in TESTS:
                evidence["checks"]["single"][label] = "FAIL"
                verdicts[label] = checked_run(root / RUNS / label, label)
                evidence["checks"]["single"][label] = "PASS"
                # The testlist reruns the same tests in the same directories:
                # keep what the single runs left before it overwrites them.
                saved = output / "single" / label
                saved.mkdir(parents=True)
                for name in ("testharness.log", REPORT, MANIFEST):
                    shutil.copy2(root / RUNS / label / name, saved / name)

        for name in TESTS:
            evidence["checks"]["batch"][name] = "FAIL"
            checked_run(root / RUNS / name, name)
            evidence["checks"]["batch"][name] = "PASS"
            save(root, output, RUNS / name, ("testharness.log", REPORT, MANIFEST))
        evidence["report_check"] = "FAIL"
        report = checked_batch(root)
        evidence["report_check"] = "PASS"
        evidence["results"] = {
            "label": report["label"],
            "cases": [
                {"test_name": name, "status": "PASS", "detail": verdicts[name]}
                for name in TESTS
            ],
        }
        save(root, output, BATCH, (REPORT,))

        for name in TESTS:
            path = BUILD / "compile" / name / f"{name}.elf"
            evidence["sha256"][str(path)] = sha256(root / path)
        binary = MODEL / "Variane_testharness"
        evidence["sha256"][str(binary)] = sha256(root / binary)
        evidence["status"], rc = "PASS", 0
    except (
        OSError,
        KeyError,
        TypeError,
        ValueError,
        yaml.YAMLError,
        subprocess.SubprocessError,
    ) as error:
        evidence["error"] = str(error)
        print(f"ERROR: {error}", file=sys.stderr)
    finally:
        evidence["finished_at"] = datetime.now(timezone.utc).isoformat()
        (output / "evidence.json").write_text(
            json.dumps(evidence, indent=2) + "\n", encoding="utf-8"
        )
        (output / "exit_code").write_text(f"{rc}\n", encoding="utf-8")
        if env.get("GITHUB_STEP_SUMMARY"):
            write_summary(evidence, Path(env["GITHUB_STEP_SUMMARY"]))
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
