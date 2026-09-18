# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

# Please refer to flows/README.md to add target

import os
import shutil
from pathlib import Path

import typer
import yaml

from flows.utils.run_cmd import run_cmd
from flows.utils.recipe_report import RecipeReport

app = typer.Typer()


def _apply_patch(patch_file, patch_cwd, report, repo_dir):
    """
    Apply a patch, doing nothing if it is already applied.

    A submodule is checked out once and patched on every call, so the operation
    has to be idempotent: `git apply --reverse --check` reverts nothing and
    stays silent when the patch is already in place, and complains otherwise.
    Returns True when the tree ends up patched.
    """
    already = run_cmd(
        cmd=["git", "apply", "--reverse", "--check", str(patch_file)],
        cwd=patch_cwd,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=None,
        timeout=60,
        check=False,
        capture_output=True,
        report=report,
    )
    if not (already or "").strip():
        report.info(f"Patch already applied, skipping: {patch_file.name}")
        return True

    result = run_cmd(
        cmd=["git", "apply", str(patch_file)],
        cwd=patch_cwd,
        env=None,
        error_patterns=None,
        warning_patterns=None,
        highlight_patterns=None,
        log_file=None,
        timeout=60,
        check=False,
        capture_output=True,
        report=report,
    )
    if result is None or "fatal:" in result.lower() or "error:" in result.lower():
        report.error(f"Failed to apply patch: {patch_file.name}")
        return False

    report.success(
        f"Applied patch: {patch_file.name} in {patch_cwd.relative_to(repo_dir)}"
    )
    return True


def _patch_submodules(dependencies, report, repo_dir):
    """
    Apply the patches declared for the Git submodules.

    Submodules are not cloned by this recipe: they are checked out by
    `git submodule update`. Patches that are not merged upstream yet are kept
    out of the submodule history so its pointer keeps tracking upstream.
    """
    submodule_patches = dependencies.get("submodule_patches") or {}
    if not submodule_patches:
        return True

    report.step("Patching Git submodules")
    results = report.metric("Submodule patches")
    all_success = True

    for sub_path, sub_config in submodule_patches.items():
        sub_dir = repo_dir / sub_path
        patches = (sub_config or {}).get("patches", [])
        if not patches:
            continue

        if not sub_dir.exists() or not any(sub_dir.iterdir()):
            report.error(
                f"Submodule not initialised: {sub_path}. "
                "Run: git submodule update --init --recursive",
                env=True,
            )
            results.add_row(status="fail", submodule=sub_path)
            all_success = False
            continue

        sub_ok = True
        for patch_spec in patches:
            if ":" in patch_spec:
                patch_file_rel, patch_subdir = patch_spec.split(":", 1)
                patch_cwd = sub_dir / patch_subdir
            else:
                patch_file_rel = patch_spec
                patch_cwd = sub_dir

            patch_file = repo_dir / patch_file_rel
            if not patch_file.exists():
                report.error(f"Patch file not found: {patch_file}", env=True)
                sub_ok = False
                continue
            if not patch_cwd.exists():
                report.error(f"Patch subdirectory not found: {patch_cwd}")
                sub_ok = False
                continue

            if not _apply_patch(patch_file, patch_cwd, report, repo_dir):
                sub_ok = False

        results.add_row(status="pass" if sub_ok else "fail", submodule=sub_path)
        if not sub_ok:
            all_success = False

    return all_success


# ==========================================================
# RECIPE - Git dependencies
# ==========================================================


@app.command()
def git_dependencies(
    repo: list[str] = typer.Option(
        [],
        "--repo",
        "-r",
        help="Specific dependency to install (e.g., 'riscv-tests', 'riscv-compliance'). If empty, install all.",
    ),
    force: bool = typer.Option(
        False, "--force", "-f", help="Force re-clone even if directory exists"
    ),
    quiet: bool = typer.Option(False, "--quiet", "-q", help="Suppress output"),
):
    """
    Install external Git dependencies for CVA6 verification.

    This recipe clones external test repositories (riscv-tests, riscv-compliance, riscv-arch-test)
    as defined in flows/config/dependencies.yml. These are NOT Git submodules.

    It also applies the patches declared under submodule_patches on the Git
    submodules, which are checked out by `git submodule update`. Those patches
    carry fixes that are not merged upstream yet, so the submodule pointer keeps
    tracking upstream. Applying them is idempotent: a patch already in place is
    skipped, so the recipe can be run repeatedly.

    Examples:
        # Install all external dependencies
        ./cook.py git-dependencies

        # Install specific dependency
        ./cook.py git-dependencies --repo riscv-tests

        # Force re-install (re-clone even if exists)
        ./cook.py git-dependencies --repo riscv-tests --force

        # Install multiple dependencies
        ./cook.py git-dependencies --repo riscv-tests --repo riscv-compliance
    """

    report = RecipeReport(
        "git-dependencies",
        out_dir=Path.cwd() / "build" / "git_dependencies",
        title="Git Dependencies",
        context={"repo": repo, "force": force},
        quiet=quiet,
    )

    # ==========================================================
    # Load dependencies configuration
    # ==========================================================
    report.step("Loading dependencies configuration")

    repo_dir = Path.cwd()
    config_dir = Path(os.getenv("CONFIG_DIR", repo_dir / "flows" / "config"))
    config_file = config_dir / "dependencies.yml"
    if not config_file.exists():
        report.error_exit(f"Configuration file not found: {config_file}", env=True)

    try:
        with config_file.open("r") as f:
            dependencies = yaml.safe_load(f)
    except yaml.YAMLError as e:
        report.error_exit(f"Failed to parse YAML configuration: {e}", env=True)

    if not dependencies:
        report.error_exit("No dependencies found in configuration file", env=True)

    # submodule_patches is not a repository to clone, it is handled separately
    # at the end of the recipe
    clonable = {k: v for k, v in dependencies.items() if k != "submodule_patches"}

    report.success(f"Loaded {len(clonable)} dependency definitions")
    # ==========================================================
    # Select dependencies to install
    # ==========================================================
    if repo:
        # Install specific dependencies
        deps_to_install = {}
        for dep_name in repo:
            if dep_name not in clonable:
                report.warning(f"Available dependencies: {', '.join(clonable.keys())}")
                report.error_exit(f"Unknown dependency: {dep_name}", env=True)
            deps_to_install[dep_name] = clonable[dep_name]
        report.info(
            f"Installing {len(deps_to_install)} specific dependency(ies): {', '.join(deps_to_install.keys())}"
        )
    else:
        # Install all dependencies
        deps_to_install = clonable
        report.info(f"Installing all {len(deps_to_install)} dependencies")

    # ==========================================================
    # Install each dependency
    # ==========================================================
    all_success = True
    results = report.metric("Dependencies installation")

    for dep_name, dep_config in deps_to_install.items():
        report.step(f"Processing dependency: {dep_name}")
        dep_ok = True
        # Validate dependency configuration
        if not isinstance(dep_config, dict):
            report.error(
                f"Invalid configuration for {dep_name}: expected dict, got {type(dep_config)}"
            )
            results.add_row(status="fail", dependency=dep_name)
            all_success = False
            continue

        repo_url = dep_config.get("repo")
        branch = dep_config.get("branch", "main")
        commit = dep_config.get("commit")
        destination = dep_config.get("destination")
        patches = dep_config.get("patches", [])
        submodules = dep_config.get("submodules", False)
        post_install = dep_config.get("post_install", {})

        # Validate required fields
        if not repo_url:
            report.error(f"Missing 'repo' field for dependency: {dep_name}")
            results.add_row(status="fail", dependency=dep_name)
            all_success = False
            continue

        if not destination:
            report.error(f"Missing 'destination' field for dependency: {dep_name}")
            results.add_row(status="fail", dependency=dep_name)
            all_success = False
            continue

        dest_path = repo_dir / destination
        # Check if destination exists
        if dest_path.exists():
            if force:
                report.warning(f"Destination exists, forcing re-clone: {dest_path}")
                try:
                    shutil.rmtree(dest_path)
                    report.info(f"Removed existing directory: {dest_path}")
                except Exception as e:
                    report.error(f"Failed to remove directory {dest_path}: {e}")
                    results.add_row(status="fail", dependency=dep_name)
                    all_success = False
                    continue
            else:
                report.warning(f"Destination already exists, skipping: {dest_path}")
                report.info("Use --force to re-clone")
                results.add_row(status="pass", dependency=dep_name)
                continue

        # Create parent directories if needed
        dest_path.parent.mkdir(parents=True, exist_ok=True)

        # Clone repository
        report.info(f"Cloning {repo_url} to {destination}")
        clone_cmd = ["git", "clone", "--branch", branch, repo_url, str(dest_path)]

        try:
            result = run_cmd(
                cmd=clone_cmd,
                cwd=repo_dir,
                env=None,
                error_patterns=None,
                warning_patterns=None,
                highlight_patterns=None,
                log_file=None,
                timeout=300,  # 5 minutes timeout
                check=False,
                capture_output=True,
                report=report,
            )

            if (
                result is None
                or "fatal:" in result.lower()
                or "error:" in result.lower()
            ):
                report.error(f"Failed to clone {dep_name}")
                results.add_row(status="fail", dependency=dep_name)
                all_success = False
                continue

            report.success(f"Successfully cloned {dep_name}")
        except Exception as e:
            report.error(f"Exception during clone: {e}", env=True)
            results.add_row(status="fail", dependency=dep_name)
            all_success = False
            continue

        # Checkout specific commit if specified
        if commit:
            report.info(f"Checking out commit: {commit}")
            checkout_cmd = ["git", "checkout", commit]

            try:
                result = run_cmd(
                    cmd=checkout_cmd,
                    cwd=dest_path,
                    env=None,
                    error_patterns=None,
                    warning_patterns=None,
                    highlight_patterns=None,
                    log_file=None,
                    timeout=60,
                    check=False,
                    capture_output=True,
                    report=report,
                )

                if (
                    result is None
                    or "fatal:" in result.lower()
                    or "error:" in result.lower()
                ):
                    report.error(f"Failed to checkout commit {commit}")
                    results.add_row(status="fail", dependency=dep_name)
                    all_success = False
                    continue

                report.success(f"Checked out commit: {commit}")
            except Exception as e:
                report.error(f"Exception during checkout: {e}", env=True)
                results.add_row(status="fail", dependency=dep_name)
                all_success = False
                continue

        # Initialize submodules if needed
        if submodules:
            report.info("Initializing submodules recursively")
            submodule_cmd = ["git", "submodule", "update", "--init", "--recursive"]

            try:
                result = run_cmd(
                    cmd=submodule_cmd,
                    cwd=dest_path,
                    env=None,
                    error_patterns=None,
                    warning_patterns=None,
                    highlight_patterns=None,
                    log_file=None,
                    timeout=300,
                    check=False,
                    capture_output=True,
                    report=report,
                )

                if (
                    result is None
                    or "fatal:" in result.lower()
                    or "error:" in result.lower()
                ):
                    report.warning(f"Failed to initialize submodules for {dep_name}")
                else:
                    report.success("Submodules initialized")
            except Exception as e:
                report.warning(f"Exception during submodule initialization: {e}")

        # Apply patches if any
        if patches:
            report.info(f"Applying {len(patches)} patch(es)")

            for patch_spec in patches:
                # Parse patch specification
                # Format: "path/to/patch.patch" or "path/to/patch.patch:subdirectory"
                if ":" in patch_spec:
                    patch_file_rel, patch_subdir = patch_spec.split(":", 1)
                    patch_cwd = dest_path / patch_subdir
                else:
                    patch_file_rel = patch_spec
                    patch_cwd = dest_path

                patch_file = repo_dir / patch_file_rel
                if not patch_file.exists():
                    report.error(f"Patch file not found: {patch_file}", env=True)
                    all_success = False
                    dep_ok = False
                    continue

                if not patch_cwd.exists():
                    report.error(f"Patch subdirectory not found: {patch_cwd}")
                    all_success = False
                    dep_ok = False
                    continue

                try:
                    if not _apply_patch(patch_file, patch_cwd, report, repo_dir):
                        all_success = False
                        dep_ok = False
                        continue
                except Exception as e:
                    report.error(f"Exception during patch apply: {e}", env=True)
                    all_success = False
                    dep_ok = False
                    continue

        # Handle post-install steps
        if post_install:
            report.info("Running post-install steps")

            # Special handling for Spike target copy (riscv-arch-test)
            if post_install.get("copy_spike_target", False):
                report.info("Copying Spike target definitions")

                # Get SPIKE_PATH from environment (defined in setenv.sh)
                spike_path = os.getenv("SPIKE_PATH")
                if not spike_path:
                    report.warning(
                        f"SPIKE_PATH not set - cannot copy arch_test_target for {dep_name}. "
                        "Please set SPIKE_PATH in flows/config/setenv.sh and source it."
                    )
                else:
                    # SPIKE_SRC_DIR = SPIKE_PATH/riscv-isa-sim
                    spike_target_src = (
                        Path(spike_path) / "riscv-isa-sim" / "arch_test_target"
                    )
                    spike_target_dst = dest_path / "riscv-target"

                    if spike_target_src.exists():
                        report.info(
                            f"Copying Spike arch_test_target from {spike_target_src} to {spike_target_dst}"
                        )

                        try:
                            # Remove existing destination if it exists
                            if spike_target_dst.exists():
                                shutil.rmtree(spike_target_dst)

                            # Copy the directory
                            shutil.copytree(spike_target_src, spike_target_dst)

                            report.success("Successfully copied Spike arch_test_target")
                        except Exception as e:
                            report.error(f"Failed to copy Spike target: {e}", env=True)
                            all_success = False
                            dep_ok = False
                    else:
                        report.warning(
                            f"Spike arch_test_target not found at {spike_target_src}. "
                            f"Expected: $SPIKE_PATH/riscv-isa-sim/arch_test_target. "
                            "Please ensure Spike is installed correctly."
                        )

        if dep_ok:
            report.success(f"Completed installation of {dep_name}")
            results.add_row(status="pass", dependency=dep_name)
        else:
            report.error(f"Completed installation of {dep_name} with errors")
            results.add_row(status="fail", dependency=dep_name)

    # ==========================================================
    # Patch the Git submodules
    # ==========================================================
    if not _patch_submodules(dependencies, report, repo_dir):
        all_success = False

    # ==========================================================
    # Final summary
    # ==========================================================
    report.end("Completed successfully" if all_success else "Completed with errors")
