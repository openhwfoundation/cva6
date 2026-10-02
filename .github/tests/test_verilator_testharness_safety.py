# Copyright 2026 OpenHW Group
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

from contextlib import contextmanager
import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

TEST_CONFIG_DIRECTORY = tempfile.TemporaryDirectory()
unittest.addModuleCleanup(TEST_CONFIG_DIRECTORY.cleanup)
TEST_CONFIG_PATH = Path(TEST_CONFIG_DIRECTORY.name)
(TEST_CONFIG_PATH / "compiler.yml").write_text(
    "test_toolchain:\n"
    "  TOOLS_PATH: /tmp\n"
    "  CLANG: null\n"
    "  GCC: gcc\n"
    "  OBJDUMP: objdump\n"
    "  NM: nm\n"
    "  TARGET_TOOLCHAIN: riscv32-unknown-elf\n",
    encoding="utf-8",
)
(TEST_CONFIG_PATH / "techno.yml").write_text("{}\n", encoding="utf-8")
os.environ["CONFIG_DIR"] = str(TEST_CONFIG_PATH)


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@contextmanager
def working_directory(path: Path):
    previous = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous)


RECIPE = load_module(
    "verilator_testharness_run_testlist",
    REPO_ROOT / "flows/recipes/verilator_testharness_run_testlist.py",
)


class VerilatorTestHarnessSafetyTest(unittest.TestCase):
    @staticmethod
    def compiled_context(root: Path):
        target = "cv32a60x_axi"
        name = "example_0"
        build_root = root / "build" / target
        compile_dir = build_root / "compile" / name
        compile_dir.mkdir(parents=True)
        (compile_dir / f"{name}.elf").write_bytes(b"ELF fixture")
        (compile_dir / "isa_string").write_text(
            "rv32imc_zicsr_zba\n", encoding="utf-8"
        )
        return RECIPE.RunContext(
            repo_dir=root,
            target=target,
            target_dir=root / "config" / "target" / target,
            build_root=build_root,
            simulation_root=build_root / "simulation" / "sim_verilator_testharness",
            generated_iss_file=build_root / "config" / "cva6.yaml",
            default_mabi="ilp32",
            privilege="msu",
            backend=RECIPE.TANDEM_BACKEND,
            tandem_enabled=True,
            env={"SPIKE_TANDEM": "1"},
            iss_timeout=500,
            sv_seed="1",
            quiet=True,
        )

    def test_nonzero_child_is_failure(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            context = self.compiled_context(Path(directory))
            with patch.object(RECIPE, "run_streaming", return_value=7):
                result = RECIPE.run_compiled_test({"test": "example"}, 0, context)
        self.assertFalse(result.passed)

    def test_zero_match_is_failure(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory) / "iss_regr.log"
            report.write_text(
                "[PASSED]: 24 matched\n[PASSED]: 0 matched\n", encoding="utf-8"
            )
            passed, detail = RECIPE.regression_report_passed(report)
            self.assertFalse(passed)
            self.assertIn("zero-match", detail)

            report.write_text("[PASSED]: 24 matched\n", encoding="utf-8")
            self.assertTrue(RECIPE.regression_report_passed(report)[0])

    def test_command_exits_when_a_case_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target_dir = root / "config" / "target" / "cv32a60x_axi"
            target_dir.mkdir(parents=True)
            (target_dir / "isa.yml").write_text("mabi: ilp32\n", encoding="utf-8")
            (target_dir / "spike.yaml").write_text(
                "spike_param_tree:\n  priv: MSU\n", encoding="utf-8"
            )
            testlist = root / "verif" / "tests" / "example.yaml"
            testlist.parent.mkdir(parents=True)
            testlist.write_text(
                "testlist:\n  - test: example\n    iterations: 1\n",
                encoding="utf-8",
            )
            source_iss = root / "verif" / "sim" / "cva6.yaml"
            source_iss.parent.mkdir(parents=True)
            source_iss.write_text("{}\n", encoding="utf-8")
            failed = RECIPE.CompiledTestResult(
                "example_0", "rv32imc", "ilp32", False
            )

            with (
                working_directory(root),
                patch.object(RECIPE, "write_iss_config"),
                patch.object(RECIPE, "run_compiled_test", return_value=failed),
                patch.object(RECIPE.Report, "dump"),
                self.assertRaises(RECIPE.typer.Exit) as raised,
            ):
                RECIPE.verilator_testharness_run_testlist(
                    target="cv32a60x_axi",
                    testlist=str(testlist.relative_to(root)),
                    test_name=None,
                    tandem_enabled=True,
                    iss_timeout=500,
                    sv_seed="1",
                    quiet=True,
                )
        self.assertEqual(raised.exception.exit_code, 1)

    def test_trace_parser_accepts_old_and_cycle_logs(self) -> None:
        sim_dir = REPO_ROOT / "verif/sim"
        sys.path.insert(0, str(sim_dir))
        sys.path.insert(0, str(sim_dir / "dv/scripts"))
        with working_directory(sim_dir):
            parser = load_module(
                "verilator_log_to_trace_csv", sim_dir / "verilator_log_to_trace_csv.py"
            )

        instruction = (
            "core   0: 0x0000000000010000 "
            "(0x00100413) addi    s0, zero, 1"
        )
        self.assertIsNotNone(parser.CORE_RE.match(instruction))
        self.assertIsNotNone(parser.CORE_RE.match("        79 | " + instruction))
        marker = "core   0: 0x0000000080000000 (0x0000a835) DASM(0000a835)"
        self.assertIsNotNone(parser.END_TRAMPOLINE_RE.match("       105 | " + marker))


if __name__ == "__main__":
    unittest.main()
