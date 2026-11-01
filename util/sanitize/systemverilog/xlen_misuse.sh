#!/bin/bash

# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Sanitize Makefile
# History       :
#

# check shell version
if [ -n "$BASH_VERSION" ]; then
  SCRIPT_PATH="$BASH_SOURCE[0]"
elif [ -n "$ZSH_VERSION" ]; then
  SCRIPT_PATH="${(%):-%N}"
else
  echo "Error: Non recognized shell."
  return
fi
export ROOT_PROJECT=$(readlink -f $(dirname "${SCRIPT_PATH}")/../../..)

# Print all XLEN use in a logical expressions
# in this order :
# unary logical operators,
# conditional operator
# binary bitwise operators,
# binary logical operators,
# binary logical equality operators
# binary case equality operators,
# binary wildcard equality operators
xlen=$(grep $ROOT_PROJECT -rinHI -E --include="*.sv" --exclude="build_config_pkg.sv" \
                             -e "(!|~|&|~&|\||~\||\^|~\^|\^~)[0-9a-zA-Z]*CVA6Cfg\.xlen" \
                             -e "CVA6Cfg\.xlen *\?:" \
                             -e "CVA6Cfg\.xlen *(&|\||\^|\^~|~^)" \
                             -e "CVA6Cfg\.xlen *(&&|\|\||->|<->)" \
                             -e "CVA6Cfg\.xlen *(==|!=)" \
                             -e "CVA6Cfg\.xlen *(===|!==)" \
                             -e "CVA6Cfg\.xlen *(==?|!=?)" | sort -u)

# Print all IS_XLEN32 or IS_XLEN64 in a arithmetic expression
# unary arithmetic operators
# binary arithmetic operators
# binary shift operators
# binary relational operators
# unary increment, decrement operators
is_xlen=$(grep $ROOT_PROJECT -rinHI -E --include="*.sv" --exclude="build_config_pkg.sv" \
                             -e "(\+|\-)[0-9a-zA-Z]*CVA6Cfg\.is_xlen(32|64)" \
                             -e "CVA6Cfg\.is_xlen(32|64) *(\+|\-|\*|\/|\*\*|%)" \
                             -e "CVA6Cfg\.is_xlen(32|64) *(>>|<<|>>>|<<<)" \
                             -e "CVA6Cfg\.is_xlen(32|64) *(<|<=|>|>=)" \
                             -e "(\+\+|\-\-)[0-9a-zA-Z]*CVA6Cfg\.is_xlen(32|64)" | sort -u)

# Check if grep commands return something
if [ -z "$xlen" ] && [ -z "$is_xlen" ]; then
    exit 0
else
    echo "There are misuses of CVA6Cfg XLEN attribute."
    echo "XLEN misuses in arethmetical operations:"
    echo "$xlen"
    echo ""
    echo "IS_XLEN misuses in logical operations:"
    echo "$is_xlen"
    exit 1
fi
