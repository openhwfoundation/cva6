# Copyright 2024 Thales DIS France SAS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Original Author: Zbigniew CHAMSKI - Thales

# Name of the target to process
TARGET ?= cv32a65x

# Components, output formats and file/directory paths.
COMPONENTS   = isa csr
FORMATS      = rst adoc # no md anymore
SPEC_DIR     = $(realpath ../riscv-config/$(TARGET)/generated)
SCRIPT       = scripts/riscv_config_gen.py
GEN_DIR      = $(TARGET)

# Input files
ISA_INPUT    = $(SPEC_DIR)/isa_gen.yaml
CSR_INPUT    = $(SPEC_DIR)/isa_gen.yaml
CUSTOM_INPUT = $(SPEC_DIR)/custom_gen.yaml

ifneq ($(wildcard $(CUSTOM_INPUT)),)
  CUSTOM_ARG = -c $(CUSTOM_INPUT)
endif

# Templates
ISA_TEMPLATE = templates/isa_template.yaml

# Updaters can be disabled by setting BARE to non-empty value.
# Bare/updated output files are kept separate to enable comparisons.
ifeq ($(BARE),)
UPDATER_OPT  = -m
ISA_UPDATER  = updaters/$(TARGET)/isa_updater.yaml
CSR_UPDATER  = updaters/$(TARGET)/csr_updater.yaml
ISA_OUTPUTS  = $(patsubst %,$(GEN_DIR)/isa/isa.%,$(FORMATS))
CSR_OUTPUTS  = $(patsubst %,$(GEN_DIR)/csr/csr.%,$(FORMATS))
else
# In 'bare' mode ($(BARE) not empty) do not apply updaters.
UPDATER_OPT  =
ISA_UPDATER  = 
CSR_UPDATER  = 
ISA_OUTPUTS  = $(patsubst %,$(GEN_DIR)/isa/isa_bare.%,$(FORMATS))
CSR_OUTPUTS  = $(patsubst %,$(GEN_DIR)/csr/csr_bare.%,$(FORMATS))
endif

# Output files
ISA_ADOC     = $(GEN_DIR)/isa/isa.adoc
ISA_MD       = $(GEN_DIR)/isa/isa.md
ISA_RST      = $(GEN_DIR)/isa/isa.rst
CSR_ADOC     = $(GEN_DIR)/csr/csr.adoc
CSR_MD       = $(GEN_DIR)/csr/csr.md
CSR_RST      = $(GEN_DIR)/csr/csr.rst
OUTPUT_FILES = $(ISA_OUTPUTS) $(CSR_OUTPUTS)

# 'isa' and 'csr' Makefile targets are not actual files.
.PHONY: $(COMPONENTS)

# By default generate both ISA and CSR documentation in updated mode. 
all: $(COMPONENTS)

adoc: $(ADOC_OUTPUTS)
isa: $(ISA_OUTPUTS)
csr: $(CSR_OUTPUTS)

%_bare.adoc: %.adoc
	mv $^ $@

%_full.adoc: %.adoc
	mv $^ $@

%_bare.md: %.md
	mv $^ $@

%_full.md: %.md
	mv $^ $@

%_bare.rst: %.rst
	mv $^ $@

%_full.rst: %.rst
	mv $^ $@

$(ISA_RST) $(ISA_MD) $(ISA_ADOC): $(ISA_INPUT) $(ISA_UPDATER) Makefile
	pip3 install -r requirements.txt
	-black scripts
	python3 $(SCRIPT) -s $(ISA_INPUT) -i $(ISA_TEMPLATE) \
          $(CUSTOM_ARG) \
          -f $(subst .,,$(suffix $@)) \
          $(UPDATER_OPT) $(ISA_UPDATER) -t $(TARGET)

$(CSR_RST) $(CSR_MD) $(CSR_ADOC): $(CSR_INPUT) $(CSR_UPDATER) Makefile
	pip3 install -r requirements.txt
	-black scripts
	python3 $(SCRIPT) -s $(CSR_INPUT) \
          $(CUSTOM_ARG) \
          -f $(subst .,,$(suffix $@)) \
          $(UPDATER_OPT) $(CSR_UPDATER) -t $(TARGET)

clean:
	$(RM) $(OUTPUT_FILES) 
