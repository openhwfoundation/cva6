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

# install the required tools
source ./verif/regress/install-verilator.sh
source ./verif/regress/install-spike.sh
source verif/regress/install-riscv-arch-test.sh

source ./verif/sim/setup-env.sh

if ! [ -n "$DV_TARGET" ]; then
  DV_TARGET=fpga_linux_cv32a6
fi

if ! [ -n "$DV_SIMULATORS" ]; then
  DV_SIMULATORS=veri-testharness,spike
fi

cd verif/sim
python3 cva6.py --testlist=../tests/testlist_riscv-csr-access-test-$DV_TARGET.yaml --target $DV_TARGET --iss_yaml=cva6.yaml --iss=$DV_SIMULATORS $DV_OPTS --linker=../sim/link.ld

cd -

