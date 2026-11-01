#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
set -euo pipefail
# The expected pre-fix assertion must not leave a core dump.
ulimit -c 0
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/../../../.." && pwd)
build_dir=${1:-$(mktemp -d "${TMPDIR:-/tmp}/cva6-csr-wfi.XXXXXX")}
csr_source=${2:-"$repo_dir/core/csr_regfile.sv"}
mkdir -p -- "$build_dir"
build_dir=$(cd -- "$build_dir" && pwd)
csr_source=$(realpath -- "$csr_source")
verilator_bin=${VERILATOR:-verilator}
"$verilator_bin" --binary --timing --assert -j 1 -CFLAGS "-std=c++20" \
  --top-module csr_wfi_tb --Mdir "$build_dir" \
  -Wno-fatal -Wno-PINMISSING -Wno-TIMESCALEMOD \
  -I"$repo_dir/core/include" \
  "$repo_dir/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv" \
  "$repo_dir/vendor/pulp-platform/obi/src/obi_pkg.sv" \
  "$repo_dir/core/include/config_pkg.sv" \
  "$repo_dir/config/target/fpga_linux_cv32a6/rtl_cfg_pkg.sv" \
  "$repo_dir/core/include/riscv_pkg.sv" \
  "$repo_dir/core/cvfpu/src/fpnew_pkg.sv" \
  "$repo_dir/core/include/ariane_pkg.sv" \
  "$repo_dir/core/include/build_config_pkg.sv" \
  "$csr_source" "$script_dir/csr_wfi_tb.sv"
"$build_dir/Vcsr_wfi_tb"
