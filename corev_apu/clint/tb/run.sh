#!/bin/sh
# Copyright 2026 OpenHW Group contributors.
# SPDX-License-Identifier: SHL-0.51

# Run from the repository root. Pass a space-free build directory if needed.
set -eu
for target in profile_perf64_axi profile_perf32_axi; do
    obj=${1:-build/clint_tb}/$target
    mkdir -p "$obj"
    verilator --binary --timing -Wno-fatal --top-module clint_tb --Mdir "$obj" \
        vendor/pulp-platform/common_cells/src/cf_math_pkg.sv \
        vendor/pulp-platform/obi/src/obi_pkg.sv vendor/pulp-platform/axi/src/axi_pkg.sv \
        core/include/config_pkg.sv core/include/build_config_pkg.sv \
        config/target/"$target"/rtl_cfg_pkg.sv corev_apu/tb/ariane_axi_pkg.sv \
        corev_apu/clint/axi_lite_interface.sv corev_apu/clint/clint.sv \
        corev_apu/clint/tb/clint_tb.sv
    "$obj"/Vclint_tb
done
