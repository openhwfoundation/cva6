# Copyright 2021 Thales DIS design services SAS
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Jean-Roch COULON - Thales

# where are the tools
if ! [ -n "$RISCV" ]; then
  echo "Error: RISCV variable undefined"
  return
fi

if ! [ -n "$DV_SIMULATORS" ]; then
  DV_SIMULATORS=vcs-testharness,spike
fi

# === Run logging: capture full terminal output to a timestamped file ===
# Logs land next to this script in verif/regress/logs/ so different smoke-test
# configs don't clobber each other. Each invocation gets a fresh file via the
# timestamp suffix.
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
SMOKE_LOG_FILE="$LOG_DIR/${SCRIPT_NAME}-$(date +%Y%m%d_%H%M%S).log"
echo "Logging full run output to: $SMOKE_LOG_FILE"
# Save current stdout/stderr on FDs 3/4 so we can restore them at the end.
# `tee -a` mirrors everything to both the log file and the terminal.
exec 3>&1 4>&2
exec > >(tee -a "$SMOKE_LOG_FILE") 2>&1
echo "=== Smoke test run started: $(date) ==="
echo "=== Script: ${BASH_SOURCE[0]} ==="

# install the required tools
if [[ "$DV_SIMULATORS" == *"veri-testharness"* ]]; then
  source ./verif/regress/install-verilator.sh
fi
source ./verif/regress/install-spike.sh

# install the required test suites
source ./verif/regress/install-riscv-compliance.sh
source ./verif/regress/install-riscv-tests.sh
source ./verif/regress/install-riscv-arch-test.sh

# setup sim env
source ./verif/sim/setup-env.sh

echo "$SPIKE_INSTALL_DIR$"

if ! [ -n "$UVM_VERBOSITY" ]; then
    export UVM_VERBOSITY=UVM_NONE
fi

export DV_OPTS="$DV_OPTS --issrun_opts=+debug_disable=1+UVM_VERBOSITY=$UVM_VERBOSITY"

CC_OPTS="-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g ../tests/custom/common/syscalls.c ../tests/custom/common/crt.S -I../tests/custom/env -I../tests/custom/common -lgcc"


cd verif/sim/

make -C ../.. clean
make clean_all
# sv39 privilege/MMU tests: all 34 tests applicable with PMP+MMU hardware
SV39_PRIV_TESTS=(
  sv39_canonical_Smode
  sv39_canonical_Umode
  sv39_global_pte_Smode
  sv39_global_pte_Umode
  sv39_invalid_pte_Smode
  sv39_invalid_pte_Umode
  sv39_misaligned_page_Smode
  sv39_misaligned_page_Umode
  sv39_mstatus_mprv_Smode
  sv39_mstatus_mprv_Umode
  sv39_mstatus_mxr_Smode
  sv39_mstatus_mxr_Umode
  sv39_nleaf_pte_DAU_Smode
  sv39_nleaf_pte_DAU_Umode
  sv39_nleaf_pte_level0_Smode
  sv39_nleaf_pte_level0_Umode
  sv39_pte_reserved_field_Smode
  sv39_pte_reserved_rwx_Smode
  sv39_pte_reserved_rwx_Umode
  sv39_pte_rsw_Smode
  sv39_pte_rsw_Umode
  sv39_satp_access_test
  sv39_spage_access_Umode
  sv39_spage_mstatus_sum_set_Smode
  sv39_svnapot_not_supported_Smode
  sv39_svpbmt_disabled_Smode
  sv39_upage_mprv_set_sum_set_Smode
  sv39_upage_mprv_set_sum_unset_Smode
  sv39_upage_mstatus_sum_set_Smode
  sv39_upage_mstatus_sum_unset_Smode
  sv39_VA_all_ones_Smode
  sv39_VA_all_zeros_Smode
)
for test in "${SV39_PRIV_TESTS[@]}"; do
  python3 cva6.py --iss_timeout=30000 \
    --testlist=../tests/testlist_riscv-mmu-sv39-arch-test-cv64a6_imafdc_sv39_pmp.yaml \
    --test "$test" --iss_yaml cva6.yaml \
    --target fpga_linux_cv64a6 \
    --iss=$DV_SIMULATORS $DV_OPTS \
    --linker=../tests/custom/privtests/priv/config/link.ld
done
python3 cva6.py --iss_timeout=30000 --testlist=../tests/testlist_riscv-compliance-cv64a6_imafdc_sv39.yaml --test rv32i-I-ADD-01 --iss_yaml cva6.yaml --target fpga_linux_cv64a6 --iss=$DV_SIMULATORS $DV_OPTS
python3 cva6.py --iss_timeout=30000 --testlist=../tests/testlist_riscv-tests-cv64a6_imafdc_sv39-p.yaml --test rv64ua-p-amoadd_d --iss_yaml cva6.yaml --target fpga_linux_cv64a6 --iss=$DV_SIMULATORS $DV_OPTS
python3 cva6.py --iss_timeout=30000 --testlist=../tests/testlist_riscv-tests-cv64a6_imafdc_sv39-p.yaml --test rv64ua-p-amoswap_w --iss_yaml cva6.yaml --target fpga_linux_cv64a6 --iss=$DV_SIMULATORS $DV_OPTS
python3 cva6.py --iss_timeout=30000 --testlist=../tests/testlist_riscv-tests-cv64a6_imafdc_sv39-p.yaml --test rv64ui-p-add --iss_yaml cva6.yaml --target fpga_linux_cv64a6 --iss=$DV_SIMULATORS $DV_OPTS
python3 cva6.py --iss_timeout=30000 --testlist=../tests/testlist_riscv-arch-test-cv64a6_imafdc_sv39.yaml --test rv64i_m-add-01 --iss_yaml cva6.yaml --target fpga_linux_cv64a6 --iss=$DV_SIMULATORS $DV_OPTS  --linker=../../config/gen_from_riscv_config/linker/link.ld
python3 cva6.py --iss_timeout=30000 --testlist=../tests/testlist_custom.yaml --test custom_test_template --iss_yaml cva6.yaml --target fpga_linux_cv64a6 --iss=$DV_SIMULATORS $DV_OPTS
python3 cva6.py --iss_timeout=30000 --c_tests ../tests/custom/hello_world/hello_world.c --iss_yaml cva6.yaml --target fpga_linux_cv64a6 --iss=$DV_SIMULATORS --gcc_opts="$CC_OPTS -nostdlib -lgcc" $DV_OPTS --linker=../../config/gen_from_riscv_config/linker/link.ld
make -C ../.. clean
make clean_all

cd -

# === Run logging: close the log and restore original stdout/stderr ===
echo "=== Smoke test run ended: $(date) ==="
echo "Full log saved to: $SMOKE_LOG_FILE"
exec 1>&3 2>&4
exec 3>&- 4>&-
