# Copyright 2026 OpenHW Foundation
# SPDX-License-Identifier: Apache-2.0
"""Select upstream tests without replacing their startup or compiler options."""

import copy
from pathlib import Path

import yaml

# Reuse upstream definitions and startup; only bound the software ISA/selection.
_RV32_PROFILE = {
    "tandem_enabled": True,
    "target": "fpga_linux_cv32a6",
    "march": "rv32imc_zicsr_zifencei",
    "mabi": "ilp32",
    "environment": "upstream-riscv-tests-p",
    "suites": {
        "basic": {
            "source": "verif/tests/base_rv32_p.yaml",
            "tests": [
                "rv32ui-p-add",
                "rv32ui-p-lw",
                "rv32ui-p-sw",
                "rv32ui-p-beq",
                "rv32ui-p-jal",
            ],
            "enabled": 5,
        },
        "integer-extra": {
            "source": "verif/tests/testlist_riscv-tests-cv32a60x-p.yaml",
            "tests": ["rv32ui-p-sub", "rv32ui-p-xor", "rv32ui-p-sll"],
            "enabled": 3,
        },
    },
}

REGRESSION_CONFIG = {
    "schema_version": 1,
    "profiles": {
        "rv32-scalar": _RV32_PROFILE,
        "rv32-superscalar": {**_RV32_PROFILE, "target": "summit_titlis"},
        "rv64": {
            **_RV32_PROFILE,
            "tandem_enabled": False,
            "target": "profile_rva20s64",
            "march": "rv64imc_zicsr_zifencei",
            "mabi": "lp64",
            "environment": "upstream-custom-crt",
            "suites": {
                "basic": {
                    "source": "verif/tests/base_rv64_p.yaml",
                    "tests": ["alu_chain_test", "fence_i_smc"],
                    "enabled": 2,
                },
            },
        },
    },
}


def names(data):
    if not isinstance(data, dict) or not isinstance(data.get("testlist"), list):
        raise ValueError("Expected a testlist sequence")
    result = []
    for entry in data["testlist"]:
        name = entry.get("test") if isinstance(entry, dict) else None
        if (
            not isinstance(name, str)
            or name in ("", ".", "..")
            or Path(name).name != name
        ):
            raise ValueError("Invalid test name")
        iterations = entry.get("iterations", 1)
        if type(iterations) is not int or iterations < 0:
            raise ValueError("Invalid iterations")
        result.extend(f"{name}_{i}" for i in range(iterations))
    if not result or len(set(result)) != len(result):
        raise ValueError("Empty or duplicate testlist")
    return result


def materialize(profile, output):
    config = copy.deepcopy(REGRESSION_CONFIG["profiles"][profile])
    output.mkdir(parents=True, exist_ok=True)
    lists, seen = {}, set()
    for suite, spec in config["suites"].items():
        path = Path(spec["source"])
        entries = yaml.safe_load(path.read_text())["testlist"]
        if "tests" in spec:
            selected = []
            for name in spec["tests"]:
                matches = [entry for entry in entries if entry.get("test") == name]
                if len(matches) != 1:
                    raise ValueError(f"Missing or duplicate source test: {name}")
                selected.append(matches[0])
            entries = selected
        data = {"testlist": copy.deepcopy(entries)}
        for entry in data["testlist"]:
            entry.setdefault("march", spec.get("march", config["march"]))
            entry.setdefault("mabi", config["mabi"])
        planned = names(data)
        if len(planned) != spec["enabled"] or seen.intersection(planned):
            raise ValueError("Reviewed count changed or cross-suite ELF names collide")
        seen.update(planned)
        destination = output / f"{profile}-{suite}.yaml"
        destination.write_text(yaml.safe_dump(data, sort_keys=False))
        lists[suite] = str(destination)
    (output / "provenance.yml").write_text(
        yaml.safe_dump(
            dict(
                profile=profile,
                config=config,
                lists=lists,
            ),
            sort_keys=False,
        )
    )
    return config, lists
