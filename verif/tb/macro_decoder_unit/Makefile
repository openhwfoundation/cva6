ROOT := ../../..

BUILD32 := .build/macro_decoder_issue_ack_test
BUILD64 := .build/macro_decoder_rv64_offsets_test

RV32_SOURCES := \
	$(ROOT)/core/include/config_pkg.sv \
	$(ROOT)/core/include/cv32a6_imac_sv32_config_pkg.sv \
	$(ROOT)/core/include/build_config_pkg.sv \
	$(ROOT)/core/include/riscv_pkg.sv \
	$(ROOT)/core/macro_decoder.sv \
	macro_decoder_issue_ack_test.sv

RV64_SOURCES := \
	$(ROOT)/core/include/config_pkg.sv \
	$(ROOT)/core/include/cv64a6_imafdc_sv39_config_pkg.sv \
	$(ROOT)/core/include/build_config_pkg.sv \
	$(ROOT)/core/include/riscv_pkg.sv \
	$(ROOT)/core/macro_decoder.sv \
	macro_decoder_rv64_offsets_test.sv

.PHONY: all macro_decoder_issue_ack_test macro_decoder_rv64_offsets_test clean

all: macro_decoder_issue_ack_test macro_decoder_rv64_offsets_test

macro_decoder_issue_ack_test:
	mkdir -p .build
	verilator \
		--binary \
		--assert \
		--timing \
		-Wno-fatal \
		-Wno-PINMISSING \
		-Wno-WIDTHTRUNC \
		-Wno-WIDTHEXPAND \
		-I$(ROOT)/core/include \
		--top-module macro_decoder_issue_ack_test \
		--Mdir $(BUILD32) \
		$(RV32_SOURCES)
	$(BUILD32)/Vmacro_decoder_issue_ack_test

macro_decoder_rv64_offsets_test:
	mkdir -p .build
	verilator \
		--binary \
		--assert \
		--timing \
		-Wno-fatal \
		-Wno-PINMISSING \
		-Wno-WIDTHTRUNC \
		-Wno-WIDTHEXPAND \
		-I$(ROOT)/core/include \
		--top-module macro_decoder_rv64_offsets_test \
		--Mdir $(BUILD64) \
		$(RV64_SOURCES)
	$(BUILD64)/Vmacro_decoder_rv64_offsets_test

clean:
	rm -rf .build
