# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Render the pipeline report (`artifacts/reports/pipeline_report.yml`,
produced by `merge-reports`) as a single self-contained HTML page:
`artifacts/reports/pipeline_report.html`.

The page inlines the vendored assets (`flows/templates/assets/`) and
the pipeline data (JSON), so it can be opened directly from the CI
artifacts or pushed as-is to the dashboard: no server, no external
resource, no token.

The rendering logic lives in the template
(`flows/templates/pipeline_report.html.jinja`): jinja2 only injects the
data and the assets; the page is built in the browser from the JSON.
"""

import json
from pathlib import Path
import yaml
import typer
from flows.utils.recipe_report import RecipeReport

try:
    import jinja2
except ImportError:  # cook.py imports every recipe: never break startup
    jinja2 = None

app = typer.Typer()

REPORTS_DIR = Path("artifacts") / "reports"
TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "templates"
TEMPLATE = "pipeline_report.html.jinja"
ASSETS = {
    "bootstrap_css": "bootstrap.min.css",
    "bootstrap_js": "bootstrap.bundle.min.js",
    "chart_js": "chart.js",
}


@app.command()
def report_html(
    input_file: Path = typer.Option(
        REPORTS_DIR / "pipeline_report.yml",
        "--input",
        "-i",
        help="Pipeline report to render (output of merge-reports)",
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress output (errors only)"
    ),
):
    """
    Render the pipeline report as a self-contained HTML page
    """
    report = RecipeReport(
        "report-html",
        title="PIPELINE REPORT HTML",
        context={"input_file": input_file},
        quiet=quiet,
    )
    if jinja2 is None:
        report.error_exit("jinja2 is not installed (see flows/requirements.txt)")
    out_file = Path.cwd() / REPORTS_DIR / "pipeline_report.html"

    # ==========================================================
    # LOAD PIPELINE REPORT
    # ==========================================================
    report.step("Load pipeline report")
    try:
        with input_file.open("r", encoding="utf-8") as f:
            pipeline = yaml.safe_load(f)
    except (OSError, yaml.YAMLError) as e:
        report.error_exit(f"Could not read {input_file}: {e}")
    if not isinstance(pipeline, dict) or "jobs" not in pipeline:
        report.error_exit(f"Not a pipeline report (no 'jobs' key): {input_file}")
    report.success(f"Loaded {input_file} ({len(pipeline['jobs'])} job(s))")

    # ==========================================================
    # RENDER HTML
    # ==========================================================
    report.step("Render HTML")
    fields = {}
    for field, filename in ASSETS.items():
        asset = TEMPLATES_DIR / "assets" / filename
        try:
            fields[field] = asset.read_text(encoding="utf-8")
        except OSError as e:
            report.error_exit(f"Could not read asset {asset}: {e}", env=True)

    # "</" is escaped so no data (log lines...) can close the inline
    # <script> tag; "<\/" is an equivalent escape inside a JSON string
    fields["pipeline_json"] = json.dumps(pipeline).replace("</", "<\\/")
    fields["title"] = pipeline.get("title") or "Pipeline report"

    try:
        template = jinja2.Template((TEMPLATES_DIR / TEMPLATE).read_text("utf-8"))
        html = template.render(**fields)
    except (OSError, jinja2.TemplateError) as e:
        report.error_exit(f"Could not render {TEMPLATE}: {e}")

    # ==========================================================
    # WRITE HTML REPORT
    # ==========================================================
    report.step("Write HTML report")
    try:
        out_file.parent.mkdir(parents=True, exist_ok=True)
        out_file.write_text(html, encoding="utf-8")
    except OSError as e:
        report.error_exit(f"Could not write {out_file}: {e}", env=True)
    report.success(f"HTML report written: {out_file}")
    report.log("Generated files", [str(out_file)])

    report.end("Completed")
