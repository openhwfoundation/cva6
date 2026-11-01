#!/bin/bash
# Copyright 2021 Thales DIS design services SAS
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Description: Combined smoke tests for all cv32a6x targets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================="
echo "Running combined smoke tests for all targets"
echo "=============================================="

echo ""
echo "----------------------------------------------"
echo "Running smoke-tests-cv32a60x.sh"
echo "----------------------------------------------"
source "$SCRIPT_DIR/smoke-tests-cv32a60x.sh"

echo ""
echo "----------------------------------------------"
echo "Running smoke-tests-cv32a65x.sh"
echo "----------------------------------------------"
source "$SCRIPT_DIR/smoke-tests-cv32a65x.sh"

echo ""
echo "----------------------------------------------"
echo "Running smoke-tests-cv32a65x_noPMP_noSuperScalar.sh"
echo "----------------------------------------------"
source "$SCRIPT_DIR/smoke-tests-cv32a65x_noPMP_noSuperScalar.sh"

echo ""
echo "----------------------------------------------"
echo "Running smoke-tests-cv32a65x_noPMP_noSuperScalar_axi.sh"
echo "----------------------------------------------"
source "$SCRIPT_DIR/smoke-tests-cv32a65x_noPMP_noSuperScalar_axi.sh"

echo ""
echo "----------------------------------------------"
echo "Running smoke-tests-fpga_linux_cv32a6.sh"
echo "----------------------------------------------"
source "$SCRIPT_DIR/smoke-tests-fpga_linux_cv32a6.sh"
