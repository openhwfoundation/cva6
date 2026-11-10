#!/bin/bash

# Copyright 2025 Thales DIS design services SAS
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Author: Maxime Colson - Thales

# Usage: bash verif/regress/Instr_tracing_test.sh
# Run from the repository root, in the cook.py environment.
#
# Runs the ITI test with iti_test.sh (cook.py), then compares the ITI and
# encoder traces with the reference flow of the E-Trace specification.
# Takes the same environment variables as iti_test.sh.
# Exit 0 if the traces match, 1 otherwise.

exit_error() {
    echo "$1" >&2
    exit ${2:-1}
}

clean_file_preserve_header() {
    local input_f="$1"
    local output_f="$2"
    local start_skip="$3"
    local end_skip="$4"

    local total_lines lines_to_keep
    total_lines=$(wc -l < "$input_f")
    lines_to_keep=$((total_lines - start_skip - end_skip))

    if [ "$lines_to_keep" -le 0 ]; then
        exit_error "Error: not enought lines in $input_f"
    fi

    {
        head -n1 "$input_f"
        tail -n "+$((start_skip + 1))" "$input_f" | head -n "$lines_to_keep"
    } | sed $'s/\r$//'> "$output_f"
}

if [ "$#" -ne 0 ]; then
    exit_error "Usage: $0" 2
fi

repo_dir="$(pwd)"
target=${ITI_TARGET:-profile_perf32_axi}
base=iti_test

set -o pipefail
if ! sim_dir=$(bash verif/regress/iti_test.sh | tee /dev/stderr | tail -n1); then
    exit_error "Error: iti_test.sh failed"
fi
set +o pipefail
exe="$repo_dir/build/$target/compile/$base/$base.elf"

workdir="$repo_dir/build/$target/instr_tracing"
rm -rf "$workdir"
mkdir -p "$workdir"

cp "$sim_dir/iti.traces" "$workdir/iti.trace"
cp "$sim_dir/encaps.traces" "$workdir/encaps.trace"

cd "$workdir"
git clone https://github.com/riscv-non-isa/riscv-trace-spec.git \
    || exit_error "Error: clone of riscv-trace-spec failed"
cd riscv-trace-spec
git checkout dca761264721068c4576eebd206e2c8b0b9d58b6 \
    || exit_error "Error: checkout of riscv-trace-spec failed"
cd referenceFlow
bash scripts/build.sh || exit_error "Error: build of the reference flow failed"

tmp_riscv="$workdir/riscv-trace-spec/referenceFlow/tests/test_files/$base.riscv"
cp "$exe" "$tmp_riscv"
if ! ./scripts/run_regression.sh -t itype3_debug --annotate --debug $tmp_riscv; then
    exit_error "Error: run_regression failed"
fi

reg_dir=$(ls -td ./regression_* 2>/dev/null | head -n1)
if [ -z "$reg_dir" ]; then
    exit_error "Error: Folder regression does not exist"
fi

iti_out="$reg_dir/itype3_debug/$base.encoder_input"
if [ ! -f "$iti_out" ]; then
    exit_error "Error: $iti_out does not exist"
fi
encod_out="$reg_dir/itype3_debug/$base.te_inst"
if [ ! -f "$encod_out" ]; then
    exit_error "Error: $encod_out does not exist"
fi

cp "$iti_out" "$workdir/iti_reg.trace"
cp "$encod_out" "$workdir/encod_reg.trace"

clean_file_preserve_header "$workdir/iti_reg.trace" "$workdir/iti_reg_cleaned.trace" 6 0
clean_file_preserve_header "$workdir/iti.trace" "$workdir/iti_cleaned.trace" 7 0

if diff -q "$workdir/iti_reg_cleaned.trace" "$workdir/iti_cleaned.trace" > /dev/null; then
    echo "SUCESS: Same ITI Traces"
else
    diff -u "$workdir/iti_reg_cleaned.trace" "$workdir/iti_cleaned.trace"
    exit_error "FAILED: ITI traces do not match"
fi

decapsuler_path="$repo_dir/corev_apu/instr_tracing/Decapsuler"

if ! make -C "$decapsuler_path" CC="${GCC_11_5_PATH:+$GCC_11_5_PATH/}g++"; then
    exit_error "Error: Compilation of Decapsuler failed"
fi

if ! "$decapsuler_path/Decapsuler" "$workdir/encaps.trace"; then
    exit_error "Error: Decapsulation failed"
fi

clean_file_preserve_header "$workdir/encod_reg.trace" "$workdir/encod_reg_cleaned.trace" 3 2
clean_file_preserve_header "$workdir/encaps.csv"  "$workdir/encaps_cleaned.trace"  3 0

if diff -q "$workdir/encod_reg_cleaned.trace" "$workdir/encaps_cleaned.trace"  > /dev/null; then
    echo "SUCESS: Same Encoder Packets"
else
    python3 "$decapsuler_path/diff_color.py" "$workdir/encaps.csv" "$workdir/encod_reg.trace"
    exit_error "FAILED: Encoder Packets do not match"
fi
