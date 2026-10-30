VERILATOR ?= verilator
ROOT := ../../..
BUILD_ROOT ?= .build
TESTS := $(patsubst %.sv,%,$(notdir $(wildcard *_test.sv)))

.PHONY: all clean $(TESTS)

RV64_CFG := $(ROOT)/core/include/cv64a6_imafdc_sv39_config_pkg.sv
RV32_CFG := $(ROOT)/core/include/cv32a6_imac_sv32_config_pkg.sv

# Build and run test $(1) with the configuration package $(3), in the build directory $(1)_$(2)
define run_xlen_test
	mkdir -p $(BUILD_ROOT)
	$(VERILATOR) --binary --assert --timing -Wno-fatal -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-MULTIDRIVEN --top-module $(1) --Mdir $(BUILD_ROOT)/$(1)_$(2) $(ROOT)/core/include/config_pkg.sv $(3) $(ROOT)/core/include/build_config_pkg.sv $(ROOT)/core/include/riscv_pkg.sv $(ROOT)/core/include/ariane_pkg.sv $(ROOT)/core/include/triggers_pkg.sv $(ROOT)/core/trigger_module.sv $(1).sv
	$(BUILD_ROOT)/$(1)_$(2)/V$(1)
endef

all: $(TESTS)

trigger_loadaddr_test:
	mkdir -p $(BUILD_ROOT)
	$(VERILATOR) --binary --assert --timing -Wno-fatal -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-MULTIDRIVEN --top-module $@ --Mdir $(BUILD_ROOT)/$@ $(ROOT)/core/include/config_pkg.sv $(ROOT)/core/include/cv64a6_imafdc_sv39_config_pkg.sv $(ROOT)/core/include/build_config_pkg.sv $(ROOT)/core/include/riscv_pkg.sv $(ROOT)/core/include/ariane_pkg.sv $(ROOT)/core/include/triggers_pkg.sv $(ROOT)/core/trigger_module.sv $@.sv
	$(BUILD_ROOT)/$@/V$@

trigger_dmode_test:
	mkdir -p $(BUILD_ROOT)
	$(VERILATOR) --binary --assert --timing -Wno-fatal -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-MULTIDRIVEN --top-module $@ --Mdir $(BUILD_ROOT)/$@ $(ROOT)/core/include/config_pkg.sv $(ROOT)/core/include/cv64a6_imafdc_sv39_config_pkg.sv $(ROOT)/core/include/build_config_pkg.sv $(ROOT)/core/include/riscv_pkg.sv $(ROOT)/core/include/ariane_pkg.sv $(ROOT)/core/include/triggers_pkg.sv $(ROOT)/core/trigger_module.sv $@.sv
	$(BUILD_ROOT)/$@/V$@

trigger_napot_test:
	mkdir -p $(BUILD_ROOT)
	$(VERILATOR) --binary --assert --timing --top-module $@ --Mdir $(BUILD_ROOT)/$@ $(ROOT)/core/include/triggers_pkg.sv $@.sv
	$(BUILD_ROOT)/$@/V$@

trigger_tdata1_test:
	$(call run_xlen_test,$@,rv64,$(RV64_CFG))
	$(call run_xlen_test,$@,rv32,$(RV32_CFG))

trigger_xtrigger_test:
	$(call run_xlen_test,$@,rv64,$(RV64_CFG))
	$(call run_xlen_test,$@,rv32,$(RV32_CFG))

trigger_icount_test:
	$(call run_xlen_test,$@,rv64,$(RV64_CFG))
	$(call run_xlen_test,$@,rv32,$(RV32_CFG))

clean:
	rm -rf $(BUILD_ROOT)
