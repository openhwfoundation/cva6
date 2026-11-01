# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Program loaded by the TestHarness run recipes, with or without pk.

A test compiled to run under the proxy kernel records the pk-build output
directory as `pk_dir` in its sw-compile manifest. The harness then loads
pk, which receives the test ELF as its argument through HTIF, and the end
of the test is the exit system call of the program, which HTIF reports
through the debug module (SimDTM): that module must stay enabled.

The SimDTM of the Spike fesvr library writes the whole pk image again
through the debug module, eight bytes per debug session, before pk can
start. Under pk, the simulators that load the DPI from shared libraries
load the one of pk-build first (`dtm_lib`), whose debug_tick tells HTIF
the ELF is preloaded, as the driver of the Verilator harness does.
"""

from pathlib import Path

from flows.utils.manifest import get_manifest_option, read_manifest

# Cycles the RVFI tracer waits for tohost before ending the run (time_out
# plusarg, 2M by default): pk boots before it runs the program
PK_CYCLE_TIMEOUT = 20_000_000


class HarnessProgram:
    """
    What the TestHarness loads for one test.

    Attributes:
        binary: ELF loaded in memory (pk, or the test itself)
        args: ELF given to the loaded binary as argument (the test under
              pk, nothing otherwise)
        tohost: address of the tohost symbol of the loaded binary
        pk: True when the test runs under the proxy kernel
        dtm_lib: DPI library of the preloaded SimDTM, under pk
    """

    def __init__(
        self, compile_dir, test_name, compile_manifest, report, pk_supported=False
    ):
        elf = Path(compile_dir) / f"{test_name}.elf"
        pk_dir = get_manifest_option(compile_manifest, "pk_dir")
        self.pk = bool(pk_dir)
        self.dtm_lib = None
        if not self.pk:
            symbols = get_manifest_option(compile_manifest, "symbols", {})
            self.binary = elf
            self.args = []
            self.tohost = symbols.get("tohost")
            if self.tohost is None:
                report.error_exit(
                    f"No tohost symbol recorded in the sw-compile manifest of "
                    f"{compile_dir}",
                    env=True,
                )
            return
        if not pk_supported:
            report.error_exit(
                f"{test_name} runs under the proxy kernel, which only the "
                f"Verilator and VCS TestHarness support",
                env=True,
            )
        pk_manifest = read_manifest(pk_dir, report)
        pk = get_manifest_option(pk_manifest, "pk")
        if not pk or not Path(pk).exists():
            report.error_exit(
                f"Missing prerequisite: proxy kernel\n"
                f"  Expected: {pk_dir}\n"
                f"  Run first: ./cook.py pk-build -t <target> -c <toolchain>",
                env=True,
            )
        self.binary = Path(pk)
        self.args = [elf]
        self.tohost = get_manifest_option(pk_manifest, "symbols", {}).get("tohost")
        dtm_lib = get_manifest_option(pk_manifest, "dtm_lib")
        self.dtm_lib = Path(dtm_lib) if dtm_lib else None
        report.info(f"Proxy kernel: {pk}, program: {elf}")

    def htif_args(self):
        "Program of HTIF, as given to a harness that reads its own argv"
        return [str(self.binary)] + [str(arg) for arg in self.args]

    def plusargs(self):
        "Program of HTIF, as given to a simulator through `++` arguments"
        return [f"++{arg}" for arg in self.htif_args()]

    def run_plusargs(self):
        """
        Plusargs the harness needs besides the program: the debug module is
        disabled except under pk, which talks to HTIF through it
        """
        if self.pk:
            return [f"+time_out={PK_CYCLE_TIMEOUT}"]
        # Nothing drives the debug module: left enabled, the SimDTM of the
        # harness halts a core built with DebugEn into its debug ROM
        # 500 cycles after reset, and the program crawls through it.
        return ["+debug_disable=1"]

    def dpi_libs(self, report):
        """
        DPI libraries to load ahead of the Spike ones, extension included:
        the preloaded SimDTM under pk
        """
        if not self.pk:
            return []
        if self.dtm_lib is None or not self.dtm_lib.exists():
            report.error_exit(
                f"No preloaded SimDTM library recorded by pk-build for "
                f"{self.binary}\n  Run first: ./cook.py pk-build -t <target> "
                f"-c <toolchain>",
                env=True,
            )
        # The simulators take the library without its extension
        return [str(self.dtm_lib.with_suffix(""))]
