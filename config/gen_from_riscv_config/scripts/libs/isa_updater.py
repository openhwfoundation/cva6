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
# Original Author: Oukalrazqou Abdessamii

""" Module is used to update isa based on yaml file called  isa updater """


import re
import yaml


def extension_update(isa_dict, isa_list, yaml_ext):
    """
    Gets the data of the updater and detect if you want to add or remove an extension
    :param isa_dict : parsed data of updater
           isa_list : list of extension read from ISA String(default supported extension)
           yaml_ext : list of extensions subset names read from isa template
    :return: list of updated extensions
    """
    # print(extension_update.__doc__)
    for element, value in isa_dict.items():
        if isinstance(value, bool):
            if isa_dict.get(element, False):
                if element in yaml_ext:
                    isa_list.append(element)
                else:
                    print(f"No info found yet for extension {element}")
        else:
            if element in isa_list:
                isa_list.remove(element)


def isa_recursive_update(original_dict, isa_dict):
    """
    Gets the data of the isa template and update the value of sub key in isa_template
    (ex: format , legal_values)
    :param original_dict : parsed data of isa template
           isa_dict : parsed data of updater
    :return: isa template updated
    """
    for key, value in isa_dict.items():
        if key in original_dict.keys():
            if isinstance(value, dict):
                isa_recursive_update(original_dict[key], value)
            elif isinstance(value, bool):
                if isinstance(original_dict[key], dict):
                    for k in original_dict[key]:
                        if isinstance(original_dict[key][k], dict):
                            for sub_key in original_dict[key][k]:
                                original_dict[key][k][sub_key] = value
                        else:
                            original_dict[key][k] = value
                else:
                    original_dict[key] = value
            else:
                original_dict[key] = value


# Extracting subset names from the YAML data
def isa_filter(parsed_data, updater, template):
    """
    create dict of filtered data from isa_template  based on supported extensions
    read from ISA String from RISC-V Yaml file
    :param parsed_data : parsed data of RISC-V Config Yaml file
           updater : parsed data of updater
           template : parsed data of isa_template
    :return:  dict of filtered data from isa_template
    """
    # Define the regular expression pattern
    isa_regex = re.compile(
        r"""
    RV(32|64|128)([IE]          # Match RV32, RV64, or RV128 followed by I or E
    [ACDFGHJLMNPQSTUV]*)      # Match zero or more letters
    ((Z\w+)|([^\W_]+))*        # Match zero or more occurrences of extensions starting with Z (e.g., Zifencei) 
                                # or other non-word characters except underscore (e.g., letters)
    (X[a-z0-9]*)*              # Match zero or more occurrences of X followed by lowercase letters or digits
    (_X[a-z0-9]*)*$            # Match zero or more occurrences of underscore followed by X and lowercase letters or digits
""",
        re.VERBOSE,
    )
    # Use search to find the pattern in the string
    extensions = []
    # If a match is found, extract the extensions
    match = isa_regex.match(parsed_data["hart0"]["ISA"])
    if match:
        character_data = match.group(2)
        characters = list(character_data)
        extensions.extend(characters)
        extension_list = match.group(3).split("_")
        extensions.extend(extension_list)
        print("Extensions:", extensions)
    else:
        print("No extensions found.")
    # Open and load the template YAML file
    data = {}
    if template is not None:
        with open(template, "r", encoding="utf-8") as file:
            data = yaml.safe_load(file)
    # Open and load the updater YAML file if exists
    modif_dict = {}
    if updater is not None:
        with open(updater, "r", encoding="utf-8") as file:
            modif_dict = yaml.safe_load(file)
    isa_recursive_update(data, modif_dict)
    yaml_extensions = [data[key]["Subset_Name"] for key in data]
    extension_update(modif_dict, extensions, yaml_extensions)
    subset_data = {}
    for ext in extensions:
        for key in data:
            if data[key]["Subset_Name"] == ext:
                subset_data[key] = data[key]
    missing_extensions = [ext for ext in extensions if ext not in yaml_extensions]
    for ext in missing_extensions:
        subset_data[ext] = {
            "Description": f"No info found yet for extension {ext}",
            "Subset_Name": ext,
        }
    return subset_data
