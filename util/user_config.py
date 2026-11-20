import sys
import re


# Public interface


def get_config(input_file, to_py=True):
    "Get the contents of `cva6_cfg` as a Python `dict`."
    lines = read_file(input_file)
    params, config = parse(lines)
    return {k: evaluate(v, params, to_py) for k, v in config.items()}


def derive_config(input_file, output_file, changes):
    """
    Change variables in the configuration and write the result.

    `changes` is a name->value dictionary.  By default it looks in cva6_cfg. If
    the value is a reference to a `localparam`, it finds the root parameter
    recursively. To avoid this, prefix the name with `*` to only look in
    cva6_cfg, or `+` to only update one specific `localparam`.
    """
    lines = read_file(input_file)
    params, config = parse(lines)
    i_params, i_config = parse(lines, get_index=True)

    for name, new_value in changes:
        if name[0] == "*":
            name = name[1:]
            replace_cfg(lines, config, i_config, name, new_value)
        elif name[0] == "+":
            name = name[1:]
            replace_param(lines, i_params, name, new_value)
        else:
            t, value = find_casting(config[name])
            root = find_root_def(value, params)
            if root:
                name, _value = root
                replace_param(lines, i_params, name, new_value)
            else:
                replace_cfg(lines, config, i_config, name, new_value)

    write_file(output_file, lines)


def parse_derive_args(argv):
    "Parse base config and changes from argv"
    base = argv[0]
    changes = list(map(lambda s: tuple(s.split("=")), argv[1:]))
    return base, changes


# Internals


def parse(lines, get_index=False):
    params = {}
    config = {}

    for index, line in enumerate(lines):
        param = parse_param(line)
        if param:
            name, value = param
            params[name] = index if get_index else value
        cfg = parse_cfg(line)
        if cfg:
            name, value = cfg
            config[name] = index if get_index else value

    return params, config


def evaluate(value, params, to_py):
    t, value = find_casting(value)

    root = find_root_def(value, params)
    if root:
        _name, value = root

    if to_py:
        py_cast = to_py_casting(t)
        if py_cast:
            value = py_cast(value)

        parsers = [array, number]
        for parser in parsers:
            if type(value) is str:
                value = parser(value)

    return value


def find_root_def(name, params):
    if name in params:
        value = params[name]
        while value in params:
            name = value
            value = params[name]
        return (name, value)
    return None


def replace_cfg(lines, config, i_config, name, new_value):
    t, _value = find_casting(config[name])
    value = build_casting(t, new_value)
    line = build_cfg(lines[i_config[name]], value)
    lines[i_config[name]] = line


def replace_param(lines, i_params, name, new_value):
    line = build_param(lines[i_params[name]], new_value)
    lines[i_params[name]] = line


# Statement parsers

param_re = re.compile(
    r"^(\s*localparam\b.*?\b)(?P<name>\w+)(\s*=\s*)(?P<value>[^;]+)(;.*)$"
)


def parse_param(line):
    match = param_re.match(line)
    if match:
        name = match["name"]
        value = match["value"].strip()
        return name, value
    else:
        return None


def build_param(line, value):
    assert param_re.match(line)
    return param_re.sub(r"\g<1>\g<2>\g<3>" + value + r"\g<5>", line)


cfg_re = re.compile(r"^(\s*)(?P<name>\w+)(\s*:\s*)(?P<value>.*?)(,?\s*)$")


def parse_cfg(line):
    match = cfg_re.match(line)
    if match:
        name = match["name"]
        value = match["value"].strip()
        return name, value
    else:
        return None


def build_cfg(line, value):
    assert cfg_re.match(line)
    return cfg_re.sub(r"\g<1>\g<2>\g<3>" + value + r"\g<5>", line)


# Expression parsers

type_re = re.compile(r"^(?P<type>\w+)\s*'\((?P<value>.*)\)$")


def find_casting(value):
    match = type_re.match(value.strip())
    if match:
        t = match["type"]
        value = match["value"].strip()
        return (t, value)
    else:
        return (None, value)


def build_casting(t, value):
    return f"{t}'({value})" if t else value


def to_py_casting(t):
    if t == "bit":
        return lambda x: bool(int(x))
    elif t == "unsigned":
        return int
    else:
        return None


number_re = re.compile(r"^\d*'s?(?P<base>.)(?P<digits>.*)$")


def number(value):
    "Parse a <len>'<base><value> `str` to `int`."
    match = number_re.match(value)
    if match:
        base = match["base"]
        digits = match["digits"]
        if base == "b":
            return BasedNumber(digits, 2)
        elif base == "o":
            return BasedNumber(digits, 8)
        elif base == "d":
            return BasedNumber(digits, 10)
        elif base == "h":
            return BasedNumber(digits, 16)
        else:
            raise Exception(f"unknown base {base}")
    else:
        return value


class BasedNumber(int):
    def __new__(cls, digits, base):
        obj = int.__new__(cls, digits, base)
        obj.base = base
        return obj

    def __repr__(self):
        if self.base == 2:
            return bin(self)
        elif self.base == 8:
            return oct(self)
        elif self.base == 16:
            return hex(self)
        else:
            return super().__repr__()


repeat_re = re.compile(r"^{\s*(?P<times>\d+)\s*{(?P<value>.*)}\s*}$")
array_re = re.compile(r"^{(?P<values>.*)}$")


def array(value):
    "Parse `str` to `list`. Only arrays of literal integers are supported."
    match = repeat_re.match(value)
    if match:
        return int(match["times"]) * [number(match["value"].strip())]
    match = array_re.match(value)
    if match:
        values = match["values"].split(",")
        return list(map(lambda value: number(value.strip()), values))
    return value


# File handling


def read_file(path):
    with open(path, "r") as f:
        return f.readlines()


def write_file(path, lines):
    with open(path, "w") as f:
        f.writelines(lines)


# Command line interface

if __name__ == "__main__":
    base, changes = parse_derive_args(sys.argv[1:])

    input_file = f"core/include/{base}_config_pkg.sv"
    output_file = "core/include/gen_config_pkg.sv"

    derive_config(input_file, output_file, changes)
