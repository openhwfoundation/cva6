#!/bin/bash
# Copyright 2025 Thales DIS design services SAS
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Author: Maxime Colson - Thales

# Usage: bash verif/regress/iti_test.sh
# Run from the repository root, in the cook.py environment.
#
# Compiles the ITI test and runs it on the TestHarness with cook.py. The
# simulation directory, holding iti.traces and encaps.traces, is printed on
# the last line, and the ELF is <compile dir>/iti_test.elf.
#
# Environment:
#   ITI_TARGET     AXI target of the TestHarness (default: profile_perf32_axi)
#   ITI_TOOLCHAIN  toolchain of $CONFIG_DIR/compiler.yml (default: gcc-15)
#   ITI_SIMULATOR  verilator or vcs (default: verilator)

set -e

target=${ITI_TARGET:-profile_perf32_axi}
toolchain=${ITI_TOOLCHAIN:-gcc-15}
simulator=${ITI_SIMULATOR:-verilator}
test_name=iti_test
build="build/$target"
tests="verif/tests/custom"

# cook.py exits 0 on failure: the verdict is in the report of the recipe.
check_report() {
    if ! grep -q "^status: pass" "$1/cook_report.yml" 2>/dev/null; then
        echo "Error: $2 failed, see $1/cook_report.yml" >&2
        exit 1
    fi
}

./cook.py sw-compile -t "$target" -c "$toolchain" --out "$test_name" \
    --linker "config/target/$target/link.ld" \
    --options g --options static --options mcmodel=medany \
    --options fvisibility=hidden --options nostartfiles \
    --inc "$tests/env" --inc "$tests/common" \
    "$tests/ITI/test_iti_asm.c" "$tests/ITI/iti_asm.S" \
    "$tests/common/syscalls.c" "$tests/common/crt.S"
check_report "$build/compile/$test_name" sw-compile

./cook.py "$simulator-testharness-comp" -t "$target"
check_report "$build/elab/sim_rtl_${simulator}_testharness" \
    "$simulator-testharness-comp"

sim_dir="$build/simulation/sim_rtl_${simulator}_testharness/$test_name"
./cook.py "$simulator-testharness-run" -t "$target" -n "$test_name"
check_report "$sim_dir" "$simulator-testharness-run"

for f in iti.traces encaps.traces; do
    if [ ! -f "$sim_dir/$f" ]; then
        echo "Error: $sim_dir/$f does not exist" >&2
        exit 1
    fi
done
realpath "$sim_dir"
