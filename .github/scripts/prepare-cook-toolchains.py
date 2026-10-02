#!/usr/bin/env python3
# Copyright 2026 OpenHW Group
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""Generate cook.py compiler configuration for GitHub runners."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import subprocess
from typing import Any

import yaml


def require_executable(path: Path) -> Path:
    if not path.is_file() or not os.access(path, os.X_OK):
        raise ValueError(f"Missing executable tool: {path}")
    return path.resolve()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def first_version_line(path: Path) -> str:
    result = subprocess.run(
        [str(path), "--version"],
        check=True,
        capture_output=True,
        text=True,
    )
    return (result.stdout or result.stderr).splitlines()[0]


def gcc_entry(riscv: Path, prefix: str) -> tuple[dict[str, Any], dict[str, Any]]:
    bin_dir = riscv / "bin"
    tools = {
        "GCC": f"{prefix}gcc",
        "OBJDUMP": f"{prefix}objdump",
        "NM": f"{prefix}nm",
    }
    paths = {name: require_executable(bin_dir / tool) for name, tool in tools.items()}
    entry = {
        "TOOLS_PATH": str(riscv),
        "CLANG": None,
        **tools,
        "TARGET_TOOLCHAIN": prefix.rstrip("-"),
    }
    metadata = {
        "version": first_version_line(paths["GCC"]),
        "target_toolchain": prefix.rstrip("-"),
        "binaries": {
            name.lower(): {"name": tools[name], "sha256": sha256(path)}
            for name, path in paths.items()
        },
    }
    return entry, metadata


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()

    try:
        toolchain_name = "github_actions_gcc"
        riscv = Path(os.environ["RISCV"]).resolve()
        prefix = os.environ["CV_SW_PREFIX"]
        output_dir = args.output_dir.resolve()
        output_dir.mkdir(parents=True, exist_ok=True)

        gcc, gcc_metadata = gcc_entry(riscv, prefix)
        compiler_data = {toolchain_name: gcc}
        environment = {
            "schema_version": 1,
            "required_toolchain": toolchain_name,
            "toolchains": {toolchain_name: gcc_metadata},
        }

        (output_dir / "compiler.yml").write_text(
            yaml.safe_dump(compiler_data, sort_keys=False), encoding="utf-8"
        )
        (output_dir / "techno.yml").write_text("{}\n", encoding="utf-8")
        (output_dir / "environment.yml").write_text(
            yaml.safe_dump(environment, sort_keys=False), encoding="utf-8"
        )
        print(f"Prepared {toolchain_name} in {output_dir}")
        print(environment["toolchains"][toolchain_name]["version"])
    except (KeyError, OSError, ValueError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"ERROR: {error}") from error


if __name__ == "__main__":
    main()
