# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

"""
Read the RTL configuration package of a target.

`config/target/<target>/rtl_cfg_pkg.sv` declares the `cva6_cfg` structure
the RTL is built from, whose fields are the parameters of the design. The
values are resolved: a field may refer to a `localparam` of the same file,
itself referring to another one.

Read-only. `util/user_config.py` *rewrites* those files, for
`hwconfig-forge` and the legacy `verif/sim/cva6.py`, and is the module to
reach for when a configuration has to be produced rather than inspected.

Values are returned as Python objects, the same way `user_config` does so
the two agree: `bit'(1)` is `True`, `unsigned'(8)` is `8`, `32'h8000_0000`
is an `int`, `{4{32'd0}}` is a list.
"""

from pathlib import Path
import re

# A field of the configuration structure: `Name: <value>,`. The trailing
# comment is dropped before matching, so a documented field parses like any
# other.
_FIELD_RE = re.compile(r"^\s*(?P<name>\w+)\s*:\s*(?P<value>.*?),?\s*$")

# A `localparam` a field may refer to
_PARAM_RE = re.compile(r"^\s*localparam\b.*?\b(?P<name>\w+)\s*=\s*(?P<value>[^;]+);")

# `bit'(1)`, `unsigned'(8)`, `int'(config_pkg::OBI_V1_6)`
_CAST_RE = re.compile(r"^(?P<type>\w+)\s*'\((?P<value>.*)\)$")

# `32'h8000_0000`, `3'b101`, `'d42`
_NUMBER_RE = re.compile(r"^\d*'s?(?P<base>[bodh])(?P<digits>[0-9a-fA-F_]+)$")

# `{4{32'd0}}` and `{a, b, c}`
_REPEAT_RE = re.compile(r"^\{\s*(?P<times>\d+)\s*\{(?P<value>.*)\}\s*\}$")
_ARRAY_RE = re.compile(r"^\{(?P<values>.*)\}$")

# Bases of a sized literal
_BASES = {"b": 2, "o": 8, "d": 10, "h": 16}

# Structure holding the parameters: the file also declares
# `cva6_user_cfg_t` values, which are not the built configuration.
_CONFIG_START = "cva6_cfg"


def _strip_comment(line):
    """
    Return a line without its trailing comment.

    Half the targets document a field that way, `FpgaAlteraEn: bit'(0),
    // for Altera (only)`, and the value has to be read without it.
    """
    index = line.find("//")
    return line if index < 0 else line[:index]


def _as_number(value):
    "Return the int of a sized literal, or the value unchanged"
    match = _NUMBER_RE.match(value)
    if not match:
        return value
    return int(match["digits"].replace("_", ""), _BASES[match["base"]])


def _as_array(value):
    "Return the list of an array literal, or the value unchanged"
    match = _REPEAT_RE.match(value)
    if match:
        return int(match["times"]) * [_as_number(match["value"].strip())]
    match = _ARRAY_RE.match(value)
    if match:
        return [_as_number(v.strip()) for v in match["values"].split(",")]
    return value


def _resolve(value, params, seen=None, cast=None):
    """
    Return the Python value of a field, `localparam` references followed.

    A reference chain is followed to its root; a cycle stops instead of
    recursing, the value being reported as the name it could not resolve.

    The cast of the outermost expression wins over what the chain carries:
    `RVC: bit'(CVA6ConfigCExtEn)` with `localparam CVA6ConfigCExtEn = 1` is
    a boolean, not the integer the localparam holds, so the cast is passed
    down rather than re-read at each step.
    """
    seen = seen or set()
    match = _CAST_RE.match(value.strip())
    if match:
        cast = cast or match["type"]
        value = match["value"].strip()

    if value in params and value not in seen:
        seen.add(value)
        return _resolve(params[value], params, seen, cast)

    if cast == "bit":
        try:
            return bool(int(value, 0))
        except ValueError:
            return value
    if cast == "unsigned":
        try:
            return int(value, 0)
        except ValueError:
            return value

    if isinstance(value, str):
        value = _as_array(value)
    if isinstance(value, str):
        value = _as_number(value)
    return value


def parse_rtl_cfg(path):
    """
    Return the parameters of a configuration package as a dict.

    Args:
        path: `config/target/<target>/rtl_cfg_pkg.sv`

    Returns:
        name -> value, e.g. `{"XLEN": 32, "RVC": True, "NrPMPEntries": 8}`

    Raises:
        OSError: the file cannot be read
    """
    params = {}
    fields = {}
    in_config = False

    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        line = _strip_comment(raw)

        param = _PARAM_RE.match(line)
        if param:
            params[param["name"]] = param["value"].strip()
            continue

        # Fields are only collected inside the built configuration: the
        # file declares other structures whose names would collide.
        if _CONFIG_START in line:
            in_config = True
            continue
        if not in_config:
            continue

        field = _FIELD_RE.match(line)
        if field and field["value"]:
            fields[field["name"]] = field["value"]

    return {name: _resolve(value, params) for name, value in fields.items()}
