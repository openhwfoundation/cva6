##-----------------------------------------------------------------------------
## Copyright 2024 Robert Bosch GmbH
##
## SPDX-License-Identifier: SHL-0.51
##
## Original Author: Konstantinos Leventos - Robert Bosch France SAS
##-----------------------------------------------------------------------------

# Where the tools are
if ! [ -n "$RISCV" ]; then
  echo "Error: RISCV variable undefined"
  return
fi

# Install the required tools
source ./verif/regress/install-spike.sh

# Setup sim env
source ./verif/sim/setup-env.sh

if ! [ -n "$DV_SIMULATORS" ]; then
  DV_SIMULATORS=vcs-uvm
fi

if ! [ -n "$UVM_VERBOSITY" ]; then
    UVM_VERBOSITY=UVM_NONE
fi

export DV_OPTS="$DV_OPTS --issrun_opts=+debug_disable=1+UVM_VERBOSITY=$UVM_VERBOSITY"

make clean
cd verif/sim/
make clean_all

export DV_TARGET=cv32a65x

python3 cva6.py --testlist=../tests/testlist_pmp-$DV_TARGET.yaml --target fpga_linux_cv32a6 --iss_yaml=cva6.yaml --iss=$DV_SIMULATORS $DV_OPTS --linker=../../config/gen_from_riscv_config/cv32a60x/linker/link.ld

make clean_all

cd -
make clean
