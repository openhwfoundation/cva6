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

RVCONFIG_DIR ?= $(shell pwd)/../../vendor/riscv/riscv-config

# Name of the target to process
TARGET ?= cv32a65x

# List of component files (inputs and processed)
COMPONENTS ?= isa custom platform

ifeq ($(findstring custom, $(COMPONENTS)),custom)
  CUSTOM_SPEC = -cspec $(SPEC_DIR)/custom_spec.yaml
endif

SPEC_DIR = $(TARGET)/spec
GEN_DIR  = $(TARGET)/generated
RVCONFIG_INPUTS = $(patsubst %,$(SPEC_DIR)/%_spec.yaml,$(COMPONENTS))


# NOTE: names of the generated files are imposed by riscv-config.
RVCONFIG_OUTPUTS= $(patsubst %,$(GEN_DIR)/%_spec_checked.yaml,$(COMPONENTS))
OUTPUT_FILES    = $(patsubst %,$(GEN_DIR)/%_gen.yaml,$(COMPONENTS))

all: $(OUTPUT_FILES)

$(GEN_DIR)/%_gen.yaml: $(GEN_DIR)/%_spec_checked.yaml
	cp $< $@

$(RVCONFIG_OUTPUTS): $(RVCONFIG_INPUTS) Makefile
	cd $(RVCONFIG_DIR) ; pip3 install -r requirements.txt
	export PYTHONPATH=$(RVCONFIG_DIR) ; \
	  python3 -m riscv_config.main \
	  --work_dir $(GEN_DIR) \
	  -ispec $(SPEC_DIR)/isa_spec.yaml \
	  -pspec $(SPEC_DIR)/platform_spec.yaml \
	  $(CUSTOM_SPEC)

clean: distclean
	$(RM) $(OUTPUT_FILES)

distclean:
	$(RM) run.log $(RVCONFIG_OUTPUTS)
