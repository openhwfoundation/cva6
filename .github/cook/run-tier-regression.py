#!/usr/bin/env python3
# Copyright 2026 OpenHW Foundation
# SPDX-License-Identifier: Apache-2.0
"""Run a selected live TestHarness regression through existing Cook recipes."""

import argparse
import os
from pathlib import Path
import subprocess
import sys

import typer
import yaml

from prepare_testlists import REGRESSION_CONFIG, materialize, names
from run_smoke import checked_report, read_yaml, run_logged

# The command is run from the repository root, like cook.py.
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from flows.utils.recipe_report import (
    RecipeReport,
)  # pylint: disable=wrong-import-position


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", required=True)
    args = parser.parse_args()
    if args.profile not in REGRESSION_CONFIG["profiles"]:
        parser.error(f"Unknown profile: {args.profile}")

    root = Path.cwd()
    output = root / "ci-results" / args.profile
    output.mkdir(parents=True, exist_ok=True)
    report = RecipeReport(
        "tier-regression",
        out_dir=root / "build" / "tier-regression" / args.profile,
        context={"profile": args.profile},
        quiet=True,
    )
    commands = report.metric("Commands")

    def run(label, arguments, directory):
        report.step(label)
        command = [sys.executable, "cook.py", *arguments]
        log = output / f"{label}.log"
        print("Running:", " ".join(command), flush=True)
        # Recipes bound simulations; Actions bounds the whole job.
        code, timed_out = run_logged(
            command, cwd=root, env=os.environ.copy(), log=log, timeout=None
        )
        commands.add_row(
            command=command, exit_code=code, log=log, recipe_report=directory
        )
        if code != 0 or timed_out:
            raise ValueError(f"{label}: exit={code}, timed_out={timed_out}; see {log}")
        checked_report(directory, arguments[0], label)
        report.success(f"{label} completed")

    try:
        report.step("Prepare testlists")
        report.add_context(
            {
                "source_revision": subprocess.check_output(
                    ["git", "rev-parse", "HEAD"], text=True
                ).strip()
            }
        )
        config, lists = materialize(args.profile, output / "testlists")
        target = config["target"]
        report.add_context({"target": target, "environment": config["environment"]})
        report.metric(
            "Selected tests",
            {suite: names(read_yaml(Path(path))) for suite, path in lists.items()},
        )
        report.warning(
            "The upstream analyzer can accept zero comparisons; review native counts."
        )
        common = [
            "-t",
            target,
            "--tandem-enabled",
            "--trace-mode",
            "notrace",
            "--quiet",
        ]
        build = root / "build" / target
        for suite, testlist in lists.items():
            run(
                f"compile-{suite}",
                [
                    "sw-compile-testlist",
                    "-t",
                    target,
                    "-c",
                    "github_actions_gcc",
                    "-l",
                    testlist,
                    "--quiet",
                ],
                build / "compile" / Path(testlist).stem,
            )
        run(
            "compile-testharness",
            [
                "verilator-testharness-comp",
                *common,
                "--jobs",
                os.environ.get("NUM_JOBS", "2"),
            ],
            build / "elab" / "sim_rtl_verilator_testharness_tandem",
        )
        for suite, testlist in lists.items():
            run(
                f"batch-{suite}",
                [
                    "testharness-run-testlist",
                    "--simulator",
                    "verilator",
                    "-l",
                    testlist,
                    *common,
                ],
                build
                / "simulation"
                / f"testharness_verilator_{Path(testlist).stem}_tandem",
            )
    except (
        OSError,
        ValueError,
        KeyError,
        TypeError,
        yaml.YAMLError,
        subprocess.SubprocessError,
    ) as error:
        report.error(str(error))
        print(f"Cook tier regression failed: {error}", file=sys.stderr)

    # Include orchestration failures in the same report used by merge-reports.
    try:
        report.end()
    except typer.Exit as error:
        return error.exit_code
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
