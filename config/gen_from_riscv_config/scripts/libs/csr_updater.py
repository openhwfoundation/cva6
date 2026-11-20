import re
import yaml


def csr_recursive_update(original_dict, csr_update):
    """
    Gets the data of the RISC-V Config Yaml file and
    update the value of sub key in RISC-V Config Yaml file
    (ex: reset-val , address)
    :param original_dict : parsed data of RISC-V Config Yaml file
           csr_update : parsed data of  CSR updater
    :return: data of RISC-V Config Yaml file updated
    """
    for key, value in csr_update.items():
        if key in original_dict:
            if isinstance(value, dict) and isinstance(original_dict[key], dict):
                if key == "rv32":
                    original_dict[key] = value
                else:
                    csr_recursive_update(original_dict[key], value)
            else:
                original_dict[key] = value


def csr_formatter(srcfile, customfile, debugfile, modifile):
    # Read original dictionary from YAML source file
    with open(srcfile, "r", encoding="utf-8") as file:
        original_dict = yaml.safe_load(file)
    if customfile:
        with open(customfile, "r", encoding="utf-8") as file:
            custom_dict = yaml.safe_load(file)
    debug_dict = {}
    riscv_config_data = original_dict.copy()
    if debugfile is not None:
        with open(debugfile, "r", encoding="utf-8") as file:
            debug_dict = yaml.safe_load(file)
        if debug_dict["hart0"]["debug_mode"]:
            riscv_config_data["hart0"].update(debug_dict["hart0"])
    if customfile:
        riscv_config_data["hart0"].update(custom_dict["hart0"])
    update_dict = {}
    if modifile is not None:
        with open(modifile, "r", encoding="utf-8") as file:
            update_dict = yaml.safe_load(file)
    print(riscv_config_data["hart0"])
    # Update original_dict with values from updated_values recursively
    csr_recursive_update(riscv_config_data["hart0"], update_dict)
    # Identify and remove keys within the range specified for each register
    keys_to_remove = []
    for key, value in update_dict.items():
        if "range" in value:
            range_value = value["range"]
            pattern = rf"{key}(\d+)"
            for k in original_dict["hart0"].keys():
                match = re.search(pattern, str(k))
                if match:
                    index = int(match.group(1))
                    if index >= range_value:
                        keys_to_remove.append(k)
    # Remove excluded keys based on the condition
    exclude_data = update_dict.get("exclude")
    if exclude_data:
        exclude_key = exclude_data.get("key")
        sub_key = exclude_data.get("sub_key")
        cond = exclude_data.get("cond")

        def remove_keys_recursive(dictionary):
            keys_to_remove = []
            for k, v in dictionary.items():
                if isinstance(v, dict):
                    if sub_key:
                        if v.get(exclude_key, {}).get(sub_key) == cond:
                            keys_to_remove.append(k)
                    else:
                        if v.get(exclude_key) == cond:
                            keys_to_remove.append(k)
                    remove_keys_recursive(v)
            for k in keys_to_remove:
                dictionary.pop(k)

        remove_keys_recursive(riscv_config_data["hart0"])
        remove_keys_recursive(riscv_config_data["hart0"])
    # Remove keys from original_dict
    for k in keys_to_remove:
        riscv_config_data["hart0"].pop(k, None)
    # Remove keys from original_dict
    for k in keys_to_remove:
        riscv_config_data.pop(k, None)
    return riscv_config_data["hart0"]
