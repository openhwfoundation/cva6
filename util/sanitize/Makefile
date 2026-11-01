# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Sanitize Makefile
# History       :
#

# root path
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
root-dir := $(abspath $(dir $(mkfile_path))/..)

ifndef CVA6_REPO_DIR
$(warning must set CVA6_REPO_DIR to point at the root of CVA6 sources -- doing it for you...)
export CVA6_REPO_DIR = $(abspath $(root-dir))
endif

all: verilog xlen

verilog:
	cd $(root-dir) && \
	verible-verilog-format --inplace $$(git ls-tree -r HEAD --name-only core | grep '\.sv$$' | grep -v '^core/include/.*_config_pkg\.sv$$')

xlen:
	bash $(root-dir)/sanitize/systemverilog/xlen_misuse.sh
