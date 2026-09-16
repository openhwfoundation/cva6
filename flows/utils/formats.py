# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Display formats for report metrics.

Metrics record pure values (int, float, str...): no markup, no unit
embedded in the value, so the data stays usable for computation
(deltas, comparisons between pipelines). How a value is *displayed* is
a separate concern, shared by the console rendering (rich) and the HTML
report rendering. This module defines each format once for both.

Available formats:

    text    default, printed as-is
    status  pass/fail/env verdict badge
    num     number (thousands separator, 2 decimals for floats)
    cycles  cycle count (number + "cycles")
    hex     hexadecimal address
    pct     percentage (number + "%")
    delta   signed difference (explicit +/- sign)
    path    file path / log link

Most columns need no annotation: `infer_fmt(key, value)` picks the
format from the column name and the value type. Use an explicit
`fmt={"column": "format"}` on the metric only for ambiguous cases
(e.g. a number that is a cycle count or a delta).
"""

# Console styles (rich color names) for the status format values
STATUS_STYLES = {
    "pass": "green",
    "fail": "red",
    "env": "yellow",
}

# Column name suffixes rendered as file paths / links by default
_PATH_KEY_SUFFIXES = ("log", "report", "path", "file")


def infer_fmt(key, value):
    """
    Infer the display format of a value from its column name and type.

    Rules (first match wins):
    - key "status" or a pass/fail/env string value -> "status"
    - int/float value -> "num"
    - string value starting with "0x" -> "hex"
    - key ending with log/report/path/file -> "path"
    - anything else -> "text"
    """
    key_l = str(key).lower()
    is_status_value = isinstance(value, str) and value.lower() in STATUS_STYLES
    if key_l == "status" or is_status_value:
        return "status"
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return "num"
    if isinstance(value, str) and value.lower().startswith("0x"):
        return "hex"
    if key_l.endswith(_PATH_KEY_SUFFIXES):
        return "path"
    return "text"


# Number rendering per format: f-string spec + suffix appended after
_NUM_RENDERERS = {
    "num": (",", ""),
    "cycles": (",", " cycles"),
    "pct": (".1f", " %"),
    "delta": ("+,", ""),
}


def render(value, fmt):
    """Return the formatted text of a value for the given format."""
    if value is None:
        return ""
    if fmt == "status":
        return str(value).upper()
    is_number = isinstance(value, (int, float)) and not isinstance(value, bool)
    if is_number and fmt in _NUM_RENDERERS:
        spec, suffix = _NUM_RENDERERS[fmt]
        if fmt == "num" and isinstance(value, float):
            spec = ",.2f"
        return f"{value:{spec}}{suffix}"
    return str(value)


# Console style (rich color name) per format
_STYLES = {
    "num": "cyan",
    "cycles": "cyan",
    "pct": "cyan",
    "delta": "cyan",
    "hex": "cyan",
    "path": "dim",
}


def style(value, fmt):
    """Return the console style (rich color name) for a value, or ""."""
    if fmt == "status":
        return STATUS_STYLES.get(str(value).lower(), "yellow")
    return _STYLES.get(fmt, "")
