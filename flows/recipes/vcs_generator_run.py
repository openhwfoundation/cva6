# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Théo GIOVINAZZI

import random
from enum import Enum
from pathlib import Path

import typer
import yaml

from flows.utils.manifest import require_prerequisite
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd

app = typer.Typer()


class SeedGen:
    """An object that will generate a pseudo-random seed for test iterations"""

    def __init__(self, start_seed, fixed_seed, seed_yaml):
        # These checks are performed with proper error messages at argument parsing
        # time, but it can't hurt to do a belt-and-braces check here too.
        assert fixed_seed is None or start_seed is None

        self.fixed_seed = fixed_seed
        self.start_seed = start_seed
        self.rerun_seed = {} if seed_yaml is None else yaml.safe_load(seed_yaml)

    def get(self, test_id, test_iter):
        """Get the seed to use for the given test and iteration"""

        if test_id in self.rerun_seed:
            # Note that test_id includes the iteration index (well, the batch index,
            # at any rate), so this makes sense even if test_iter > 0.
            return self.rerun_seed[test_id]

        if self.fixed_seed is not None:
            # Checked at argument parsing time
            assert test_iter == 0
            return self.fixed_seed

        if self.start_seed is not None:
            return self.start_seed + test_iter

        # If the user didn't specify seeds in some way, we generate a random seed
        # every time
        return random.getrandbits(31)


class Extension(str, Enum):
    zba = "zba"
    zbb = "zbb"
    zbc = "zbc"
    zbs = "zbs"
    zcb = "zcb"
    zcmp = "zcmp"
    zcmt = "zcmt"
    x = "x"


class InstrType(str, Enum):
    load_store = "load_store"
    branch_jump = "branch_jump"
    fence = "fence"
    csr_instr = "csr_instr"
    dret = "dret"
    ebreak = "ebreak"
    unaligned_load_store = "unaligned_load_store"


# ==========================================================
# RECIPE
# ==========================================================


@app.command()
def vcs_generator_run(
    test_name: str = typer.Option(..., "--testname", "-n", help="Test name to run"),
    type_instr: list[InstrType] = typer.Option(
        [],
        "--type-instr",
        help="Type instruction to enable (ex: load_store,fence,branch_jump)",
    ),
    gen_test: str = typer.Option("cva6_instr_base_test_c", help="Gen test to run"),
    iterations: int = typer.Option(
        1, "--iterations", "-i", help="Number of iterations"
    ),
    batch_size: int = typer.Option(1, help="Number of tests to generate per run batch"),
    instr_cnt: int = typer.Option(
        300, help="Number of instructions to generate (+instr_cnt)"
    ),
    extensions: list[Extension] = typer.Option(
        [],
        "--extension",
        "-e",
        help="Extensions to enable. Repeat flag for multiple: -e zbb -e zbs",
    ),
    directed_instrs: list[str] = typer.Option(
        [],
        "--directed-instr",
        "-d",
        help="Directed instruction streams (e.g. -d 'cva6_load_store_rand_instr_stream_c,10')",
    ),
    illegal_instr_ratio: int = typer.Option(0, help="Illegal instruction ratio"),
    unsupported_instr_ratio: int = typer.Option(
        0, help="Unsupported instruction ratio"
    ),
    num_of_sub_program: int = typer.Option(0, help="Number of sub-programs"),
    seed: int = typer.Option(None, help="randomized if not provided"),
    tvec_alignment: int = typer.Option(8, help="tvec_alignment value (int)"),
    verbose: bool = typer.Option(
        False, "--verbose", "-v", help="Enable UVM_HIGH verbosity"
    ),
    opts: list[str] = typer.Option(
        [],
        "--options",
        help="Directed instruction streams (e.g. -d 'cva6_load_store_rand_instr_stream_c,10')",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    RISC-V DV Simulate command
    """
    report = RecipeReport(
        "vcs-generator-run",
        title="DV SIMULATE GENERATOR",
        context={
            "target": "cv32a65x",
            "test_name": test_name,
            "type_instr": type_instr,
            "gen_test": gen_test,
            "iterations": iterations,
            "batch_size": batch_size,
            "instr_cnt": instr_cnt,
            "extensions": extensions,
            "directed_instrs": directed_instrs,
            "illegal_instr_ratio": illegal_instr_ratio,
            "unsupported_instr_ratio": unsupported_instr_ratio,
            "num_of_sub_program": num_of_sub_program,
            "seed": seed,
            "tvec_alignment": tvec_alignment,
            "verbose": verbose,
            "opts": opts,
        },
        quiet=quiet,
    )

    # Seed Initialisation
    seed_gen = SeedGen(None, seed, None)

    # ==========================================================
    # PATHS
    # ==========================================================

    repo_dir = Path.cwd()
    build_dir = repo_dir / "build" / "dv"
    simv_path = build_dir / "simv"
    output_dir = repo_dir / "build" / "cv32a65x" / "dv_generated" / test_name
    report.set_out_dir(output_dir)

    require_prerequisite(
        simv_path,
        "compiled random test generator (simv)",
        "./cook.py vcs-generator-comp",
        report=report,
    )

    output_dir.mkdir(parents=True, exist_ok=True)
    asm_dir = output_dir / "asm_tests"
    asm_dir.mkdir(parents=True, exist_ok=True)

    # ==========================================================
    # OPTIONS
    # ==========================================================

    base_options = [
        f"+instr_cnt={instr_cnt}",
        f"+num_of_sub_program={num_of_sub_program}",
        f"+illegal_instr_ratio={illegal_instr_ratio}",
        f"+unsupported_instr_ratio={unsupported_instr_ratio}",
    ]

    # directed_instr
    for idx, instr in enumerate(directed_instrs):
        base_options.append(f"+directed_instr_{idx}={instr}")

    active_extensions = [ext.value for ext in extensions]

    # enable_extension
    for ext in Extension:
        val = 1 if ext.value in active_extensions else 0
        base_options.append(f"+enable_{ext.value}_extension={val}")

    # active_instr
    active_instr_types = [instr.value for instr in type_instr]
    for instr in InstrType:
        # if type is in InstrType -> activate (no_X=0)
        val = 0 if instr.value in active_instr_types else 1
        base_options.append(f"+no_{instr.value}={val}")

    # verbose
    if verbose:
        base_options.append("+UVM_VERBOSITY=UVM_HIGH")

    # tvec_alignment
    base_options.append(f"+tvec_alignment={tvec_alignment}")

    batch_cnt = 1
    if batch_size > 0:
        batch_cnt = int((iterations + batch_size - 1) / batch_size)
    report.info(f"Running {test_name} with {batch_cnt} batches")

    sim_seed = {}
    for i in range(0, batch_cnt):
        test_id = f"{test_name}_{i}"

        rand_seed = seed_gen.get(test_id, i * batch_size)
        sim_seed[test_id] = str(rand_seed)

        if i < batch_cnt - 1:
            test_cnt = batch_size
        else:
            test_cnt = iterations - i * batch_size

        cmd_options = [
            f"+UVM_TESTNAME={gen_test}",
            f"+num_of_tests={test_cnt}",
            f"+start_idx={i * batch_size}",
            f"+asm_file_name={asm_dir}/{test_name}",
            f"-l {output_dir}/sim_{test_name}_{i}.log",
            f"+ntb_random_seed={rand_seed}",
        ]

        # select options
        if opts:
            sim_cmd = [str(simv_path)] + cmd_options + opts
        else:
            sim_cmd = [str(simv_path)] + cmd_options + base_options
        report.step(f"Run Batch {i + 1}/{batch_cnt} (Tests: {test_cnt})")

        # ==========================================================
        # LAUNCH SIMV
        # ==========================================================

        run_cmd(
            cmd=sim_cmd,
            report=report,
            cwd=repo_dir,
            env=None,
            error_patterns=[r"\[ERROR\]", r"^UVM_ERROR", r"Fatal"],
            warning_patterns=[r"\[WARNING\]", r"^UVM_WARNING"],
            log_file=output_dir / f"run_batch_{i}.log",
            timeout=3600,
            check=False,
            capture_output=False,
        )

    # ==========================================================
    # Seed Files
    # ==========================================================
    if sim_seed:
        dv_generated_dir = repo_dir / "build" / "cv32a65x" / "dv_generated"
        seedlist_path = dv_generated_dir / "seedlist.yaml"

        dv_generated_dir.mkdir(parents=True, exist_ok=True)

        with open(seedlist_path, "a", encoding="utf-8") as seedlist_file:
            yaml.dump(sim_seed, seedlist_file, default_flow_style=False)

        report.info(f"Seeds appended to {seedlist_path}")

        seed_path = output_dir / "seed.yaml"
        with open(seed_path, "w", encoding="utf-8") as seed_file:
            yaml.dump(sim_seed, seed_file, default_flow_style=False)

    # ==========================================================
    # Clean
    # ==========================================================
    report.step("Clean")

    target_dir = repo_dir

    # Remove simv_start_maps_
    for map_file in target_dir.glob("simv_start_maps_*.txt"):
        if map_file.is_file():
            map_file.unlink()
            report.info(f"File {map_file} deleted")

    # Remove ucli.key
    ucli_file = target_dir / "ucli.key"
    if ucli_file.exists():
        ucli_file.unlink()
        report.info(f"File {ucli_file} deleted")

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    generated = []
    for i in range(iterations):
        file = asm_dir / f"{test_name}_{i}.S"
        if file.exists():
            report.info(f"> {file}")
            generated.append(str(file.relative_to(repo_dir)))

    report.success("Instruction generation complete")

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")


if __name__ == "__main__":
    app()
