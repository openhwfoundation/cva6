# Copyright 2026 huaiyin
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0

VERILATOR ?= verilator
ROOT := ../../..
BUILD_ROOT ?= .build
TESTS := trigger_dmode_test trigger_loadaddr_test trigger_match_ge_lt_test trigger_napot_test
COMMON_SOURCES := \
	$(ROOT)/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv \
	$(ROOT)/vendor/pulp-platform/obi/src/obi_pkg.sv \
	$(ROOT)/core/include/config_pkg.sv
RTL_SOURCES := \
	$(ROOT)/core/include/build_config_pkg.sv \
	$(ROOT)/core/include/riscv_pkg.sv \
	$(ROOT)/core/include/ariane_pkg.sv \
	$(ROOT)/core/include/triggers_pkg.sv \
	$(ROOT)/core/trigger_module.sv
VERILATOR_FLAGS := --binary --assert --timing -Wno-fatal \
	-Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-MULTIDRIVEN -Wno-PINMISSING \
	-I$(ROOT)/core/include

.PHONY: all $(TESTS) trigger_match_ge_lt_test_rv32 clean

all: $(TESTS) trigger_match_ge_lt_test_rv32

$(TESTS): %: %.sv
	mkdir -p $(BUILD_ROOT)
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module $@ --Mdir $(BUILD_ROOT)/$@ \
		$(COMMON_SOURCES) $(ROOT)/config/target/profile_perf64_axi/rtl_cfg_pkg.sv \
		$(RTL_SOURCES) $<
	$(BUILD_ROOT)/$@/V$@

trigger_match_ge_lt_test_rv32: trigger_match_ge_lt_test.sv
	mkdir -p $(BUILD_ROOT)
	$(VERILATOR) $(VERILATOR_FLAGS) --top-module trigger_match_ge_lt_test \
		--Mdir $(BUILD_ROOT)/$@ $(COMMON_SOURCES) \
		$(ROOT)/config/target/profile_perf32_axi/rtl_cfg_pkg.sv $(RTL_SOURCES) $<
	$(BUILD_ROOT)/$@/Vtrigger_match_ge_lt_test

clean:
	rm -rf $(BUILD_ROOT)
