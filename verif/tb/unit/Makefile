VERILATOR ?= verilator
ROOT := ../../..
BUILD_ROOT ?= .build
TESTS := trigger_dmode_test trigger_loadaddr_test trigger_match_ge_lt_test trigger_napot_test

.PHONY: all $(TESTS) clean

all: $(TESTS)

$(TESTS): %: %.sv
	mkdir -p $(BUILD_ROOT)
	$(VERILATOR) --binary --assert --timing -Wno-fatal -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-MULTIDRIVEN -Wno-PINMISSING -I$(ROOT)/core/include --top-module $@ --Mdir $(BUILD_ROOT)/$@ $(ROOT)/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv $(ROOT)/vendor/pulp-platform/obi/src/obi_pkg.sv $(ROOT)/core/include/config_pkg.sv $(ROOT)/config/target/profile_perf64_axi/rtl_cfg_pkg.sv $(ROOT)/core/include/build_config_pkg.sv $(ROOT)/core/include/riscv_pkg.sv $(ROOT)/core/include/ariane_pkg.sv $(ROOT)/core/include/triggers_pkg.sv $(ROOT)/core/trigger_module.sv $<
	$(BUILD_ROOT)/$@/V$@

clean:
	rm -rf $(BUILD_ROOT)
