#!/usr/bin/env bash
# Copyright 2026 OpenHW Group
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

set -eo pipefail

if [[ -z "${RISCV:-}" ]]; then
  echo "Error: RISCV variable undefined" >&2
  exit 1
fi

source verif/sim/setup-env.sh
set -u

# These are self-checking architectural tests.  Do not enable Spike tandem
# execution because the OpenHW RV64 Spike target does not describe these PMP
# regions.
unset SPIKE_TANDEM

readonly standard_target="${DV_TARGET:-cv64a6_imafdc_sv39}"
readonly linker="../../config/gen_from_riscv_config/linker/link.ld"
readonly testlist="../tests/testlist_issues.yaml"
readonly no_mmu_options="${standard_target}"\
" +CVA6ConfigDcacheFlushOnFence=0"\
" +CVA6ConfigDcacheFlushOnFenceI=0"\
" +CVA6ConfigDcacheInvalidateOnFlush=0"\
" *MmuPresent=0"

cd verif/sim

run_test() {
  local test_name="$1"
  local target="$2"
  shift 2

  python3 cva6.py \
    --testlist="${testlist}" \
    --test="${test_name}" \
    --target="${target}" \
    --iss_yaml=cva6.yaml \
    --iss=veri-testharness \
    --linker="${linker}" \
    --issrun_opts=+debug_disable=1 \
    "$@"
}

# Discard a model left by a previous run with a different configuration.
make -C ../.. clean

run_test pmp-lsu-transaction-rv64 "${standard_target}"
run_test pmp-amo-access-fault-rv64 "${standard_target}"

# The generated model does not track configuration variables as dependencies,
# so discard it before switching to the no-MMU configuration.
make -C ../.. clean

run_test pmp-lsu-transaction-no-mmu-rv64 hwconfig \
  --hwconfig_opts="${no_mmu_options}"

# HLVX carries its execute-permission requirement with the response too.
make -C ../.. clean
run_test pmp-hlvx-access-fault-rv64 cv64a6_imafdch_sv39

# An instruction guest-page fault must outrank the PMP/PMA check that runs on
# the address forwarded for the failed translation (issue #3597).  Same
# configuration as the run above, so the model is reused.
run_test pmp-instr-guest-page-fault-priority-rv64 cv64a6_imafdch_sv39

make -C ../.. clean
run_test pmp-hlvx-access-fault-rv64 hwconfig \
  --hwconfig_opts="cv64a6_imafdch_sv39 +CVA6ConfigDcacheFlushOnFence=0 +CVA6ConfigDcacheFlushOnFenceI=0 +CVA6ConfigDcacheInvalidateOnFlush=0 *MmuPresent=0"
