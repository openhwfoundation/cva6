# Copyright 2025 Thales DIS France SAS
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
# Original Author: Oukalrazqou Abdessamii


""" Module is used to update Spike based on yaml file called  spike updater """
import re
import yaml
from yaml import BaseLoader


def spike_recursive_update(original_dict, spike_update):
    """
    Gets the data of the RISC-V Config Yaml file and
    update the value of sub key in RISC-V Config Yaml file
    (ex: priv , pmpaddr)
    :param original_dict : parsed data of  Spike Yaml file
           spike_update : parsed data of   Spike updaters
    :return: data of Spike Yaml file updated
    """
    for key, value in spike_update.items():
        if key in original_dict:
            if isinstance(value, dict) and isinstance(original_dict[key], dict):
                if key == "cores":
                    original_dict[key] = value
                else:
                    csr_recursive_update(original_dict[key], value)
            else:
                original_dict[key] = value


def is_hex_string(s):
    return bool(re.match(r"'?(0x[0-9a-fA-F]+)'?", s))


def custom_convert(data):
    if isinstance(data, dict):
        return {k: custom_convert(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [custom_convert(item) for item in data]
    elif isinstance(data, str):
        if data.lower() == "true":
            return True
        elif data.lower() == "false":
            return False
        elif data.isdigit():
            return int(data)
        elif is_hex_string(data.strip()):
            return int(data, 16)
    return data


def spike_formatter(original_dict, modifile):
    # Read original dictionary from YAML  Source file
    updated_values = {}
    if modifile is not None:
        with open(modifile, "r", encoding="utf-8") as file:
            updated_values = yaml.load(file, Loader=BaseLoader)
    # Update original_dict with values from updated_values recursively
    spike_recursive_update(original_dict["spike_param_tree"], updated_values)
    original_dict = custom_convert(original_dict)
    return original_dict
