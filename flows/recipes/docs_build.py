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
Build the CVA6 documentation (AsciiDoctor specifications + Sphinx).

Two stages, for a target given with `-t`:

1. the **specifications**, one AsciiDoctor run per manual: the RISC-V
   privileged and unprivileged ones, and the CVA6 design manual. Their
   sources are assembled in the output directory together with the
   `.adoc` generated from the RTL configuration of the target;
2. the **user manual**, rendered by Sphinx from the `.rst` of `docs/`.

The RISC-V manuals come from the `riscv-isa-manual` submodule. Their
AsciiDoctor extensions are expected on the machine, a missing one being
reported as an environment failure.

With `--readthedoc` instead of `-t`, the documentation of every chapter
of `docs/` that embeds a manual is prepared in place: each rendered
`.html` is placed next to its page, and ReadTheDocs runs Sphinx on
`docs/` itself afterwards. The shared machinery lives in
`flows/utils/docs_manual.py`.
"""

from pathlib import Path
import shutil
import typer

from flows.utils.autocompletion import autocompletion_target
from flows.utils.docs_manual import (
    MANUALS,
    SPHINX_SKIPPED_SOURCES,
    SPHINX_WARNING_RE,
    _check_prerequisites,
    _docs_build_readthedoc,
    _drop_work_dir,
    _render_manual,
    read_parameters,
    write_user_cfg_rst,
)
from flows.utils.manifest import write_manifest
from flows.utils.recipe_report import RecipeReport
from flows.utils.run_cmd import run_cmd

app = typer.Typer()


@app.command()
def docs_build(
    target: str = typer.Option(
        None,
        "--target",
        "-t",
        help="CVA6 user configuration the specifications document",
        autocompletion=autocompletion_target,
    ),
    readthedoc: bool = typer.Option(
        False,
        "--readthedoc",
        help="Prepare the documentation of every chapter of docs/ that "
        "embeds a manual, in place, as `make -C docs prepare` did: each "
        "rendered `.html` is placed next to its page and `user_cfg_doc.rst` "
        "is regenerated. Sphinx is left to ReadTheDocs, which runs "
        "sphinx-build itself. Takes no `-t`.",
    ),
    manual: list[str] = typer.Option(
        [],
        "--manual",
        "-m",
        help="Manual to build: priv, unpriv or design (default: all of them)",
    ),
    sphinx: bool = typer.Option(True, help="Render the user manual with Sphinx"),
    doc_format: str = typer.Option(
        "html", "--format", help="Format of the specifications: html, pdf or both"
    ),
    strict: bool = typer.Option(False, help="Fail on an AsciiDoctor or Sphinx warning"),
    clean: bool = typer.Option(True, help="Clean working dir before"),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Build the CVA6 documentation (specifications + user manual)
    """
    report = RecipeReport(
        "docs-build",
        title="DOCUMENTATION BUILD",
        context={
            "target": target,
            "readthedoc": readthedoc,
            "manual": manual,
            "sphinx": sphinx,
            "doc_format": doc_format,
            "strict": strict,
            "clean": clean,
        },
        quiet=quiet,
    )

    repo_dir = Path.cwd()
    docs_dir = repo_dir / "docs"

    if readthedoc:
        _docs_build_readthedoc(repo_dir, docs_dir, strict, clean, report)
        return

    if target is None:
        report.error_exit(
            "No target given\n"
            "  Give one with -t, or --readthedoc to prepare the "
            "documentation of every chapter of docs/ that embeds a manual.",
            env=True,
        )

    out_dir = repo_dir / "build" / target / "docs"
    report.set_out_dir(out_dir)

    manuals = list(manual) or list(MANUALS)
    unknown = [m for m in manuals if m not in MANUALS]
    if unknown:
        report.error_exit(
            f"Unknown manual(s): {', '.join(unknown)}\n"
            f"  Expected one of {', '.join(MANUALS)}",
            env=True,
        )
    if doc_format not in ("html", "pdf", "both"):
        report.error_exit(
            f"Unknown format {doc_format!r}: expected html, pdf or both", env=True
        )
    formats = (
        ["html"]
        if doc_format == "html"
        else (["pdf"] if doc_format == "pdf" else ["html", "pdf"])
    )

    # ==========================================================
    # CHECK PREREQUISITES
    # ==========================================================
    renderers, rtl_cfg, doc_cfg = _check_prerequisites(
        docs_dir, target, manuals, formats, sphinx, report
    )

    # ==========================================================
    # CLEAN
    # ==========================================================
    report.step("Clean")
    if clean:
        try:
            if out_dir.exists():
                shutil.rmtree(out_dir)
                report.info(f"remove {out_dir}")
        except OSError as e:
            report.error_exit(f"Clean error : {e}", env=True)
    else:
        report.info(f"Skip cleaning {out_dir}")

    out_dir.mkdir(parents=True, exist_ok=True)
    report.info(f"create {out_dir}")

    # ==========================================================
    # SPECIFICATIONS
    # ==========================================================
    # One AsciiDoctor run per manual and per format. A manual that fails
    # does not stop the others: they are independent documents, and the
    # report is more useful listing all of them.
    documents = []
    if manuals:
        results = report.metric("Specifications")
        for name in manuals:
            report.step(f"Build the {name} specification")

            for fmt in formats:
                final = _render_manual(
                    out_dir,
                    repo_dir,
                    docs_dir,
                    target,
                    rtl_cfg,
                    doc_cfg,
                    name,
                    fmt,
                    renderers,
                    strict,
                    report,
                )
                if final is not None:
                    documents.append(final)
                    results.add_row(
                        status="pass", manual=name, format=fmt, document=final.name
                    )
                else:
                    results.add_row(status="fail", manual=name, format=fmt, document="")

        report.print_metric(results)
        if results.failed:
            report.error("Some specifications could not be built")
        else:
            report.success(f"{len(documents)} specification(s) built")

        # The working directory of a manual is its sources copied together
        # with the generated `.adoc`: twenty megabytes per manual, of which
        # nothing is read once the document is rendered. Dropped so the
        # output directory holds the documents and the logs only, which is
        # what a CI job archives.
        for name in manuals:
            _drop_work_dir(out_dir, name, report)

    # ==========================================================
    # USER MANUAL
    # ==========================================================
    html_dir = out_dir / "html"
    if sphinx:
        report.step("Render the user manual")

        # Sphinx reads a copy of docs/: the user configuration reference is
        # generated into its sources, where its toctree expects it, and the
        # checkout stays untouched. The manual submodule and the sources of
        # the AsciiDoctor manuals are left out, none of them being part of
        # the user manual.
        sphinx_src = out_dir / "sphinx_src"
        shutil.copytree(
            docs_dir,
            sphinx_src,
            ignore=lambda folder, names: (
                SPHINX_SKIPPED_SOURCES if Path(folder) == docs_dir else []
            ),
        )
        write_user_cfg_rst(
            sphinx_src / "01_cva6_user" / "user_cfg_doc.rst",
            read_parameters(repo_dir, rtl_cfg),
            doc_cfg,
        )

        log_file = out_dir / "sphinx.log"
        sphinx_cmd = ["sphinx-build", ".", str(html_dir)]
        if strict:
            sphinx_cmd.insert(1, "-W")

        run_cmd(
            cmd=sphinx_cmd,
            report=report,
            cwd=sphinx_src,
            env=None,
            error_patterns=["ERROR:|Sphinx error"],
            warning_patterns=["WARNING:"],
            highlight_patterns=None,
            log_file=log_file,
            timeout=3600,
            check=False,
            capture_output=False,
        )

        index = html_dir / "index.html"
        if not index.exists():
            report.analyze_log(
                log_file,
                name="sphinx.log analysis",
                error_patterns=["ERROR:", "Sphinx error", "Traceback"],
                env_patterns=["No module named", "command not found"],
                fail_on_error=False,
            )
            report.error_exit(f"User manual not rendered: {index}")

        pages = len(list(html_dir.rglob("*.html")))
        n_warn = 0
        try:
            for line in log_file.read_text(
                encoding="utf-8", errors="replace"
            ).splitlines():
                if SPHINX_WARNING_RE.search(line):
                    n_warn += 1
        except OSError as e:
            report.warning(f"Could not read {log_file}: {e}")

        shutil.rmtree(sphinx_src, ignore_errors=True)

        report.metric("User manual", {"pages": pages, "warnings": n_warn})
        report.kpi("docs_pages", pages, unit="pages", better="higher")
        report.kpi("docs_warnings", n_warn, unit="warnings", better="lower")
        report.set_label(f"{pages} pages")
        report.success(f"User manual rendered: {index} ({pages} pages)")
        if n_warn:
            report.warning(f"{n_warn} Sphinx warning(s), see {log_file}")

    # ==========================================================
    # BUILD MANIFEST
    # ==========================================================
    write_manifest(
        out_dir,
        "docs-build",
        {
            "target": target,
            "manual": manuals,
            "sphinx": sphinx,
            "doc_format": doc_format,
            "strict": strict,
        },
        report=report,
    )

    # ==========================================================
    # List
    # ==========================================================
    report.step("Generated files")
    generated = []
    if sphinx and (html_dir / "index.html").exists():
        report.info(f"> {html_dir / 'index.html'}")
        generated.append(str((html_dir / "index.html").relative_to(repo_dir)))
    for document in documents:
        report.info(f"> {document}")
        generated.append(str(document.relative_to(repo_dir)))

    # ==========================================================
    # BUILD REPORT
    # ==========================================================
    report.log("Generated files", generated)

    report.end("Completed")
