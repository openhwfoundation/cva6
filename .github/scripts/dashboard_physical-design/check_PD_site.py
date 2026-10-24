#!/usr/bin/env python3
# Copyright 2026 OpenHW Group
# SPDX-License-Identifier: Apache-2.0
"""Check that the download links of the PD dashboard resolve in the site to deploy.

The run records hold site-relative paths of the raw files (raw_json_path,
logs_zip_path), built by extract_PD_metrics.py, while PD-dashboard.yml copies the
data directory into the site. A path changed on one side only, or raw files
deleted by mistake, leaves dead download links: this reports them as warnings.
It does not fail: a run with dead links still belongs on the dashboard, and the
dashboard must keep being updated with new runs. Raw files lost from the data
branch cannot be restored, so the same warnings come back at every update.

    python3 check_PD_site.py --data-dir /tmp/PD-data --site-dir /tmp/dash-site
"""

import argparse
import sys
from pathlib import Path

# Same flows and records as the collected data (script in this directory)
from extract_PD_metrics import PD_FLOWS, annotate, load_existing

LINK_FIELDS = ("raw_json_path", "logs_zip_path")

# Dead links reported as annotations, after their count: GitHub shows 10 warnings
# per step. The step log lists them all.
MAX_ANNOTATED = 9


def check_links(data_dir: Path, site_dir: Path) -> tuple:
    """(number of links checked, descriptions of the dead ones)."""
    checked = 0
    dead = []
    for flow in PD_FLOWS.values():
        for run in load_existing(data_dir / flow["runs_file"]):
            for f in run.get("flows", []):
                for field in LINK_FIELDS:
                    path = f.get(field)
                    if not path:
                        continue
                    checked += 1
                    if not (site_dir / path).is_file():
                        dead.append(f"{flow['runs_file']}, run {run.get('run_number')} (id={run['id']}), "
                                    f"{f.get('arch')}/{f.get('config')}: {field} {path}")
    return checked, dead


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check that the download links of the PD dashboard resolve in the site",
    )
    parser.add_argument("--data-dir", required=True, help="Directory holding the runs files")
    parser.add_argument("--site-dir", required=True, help="Site directory, root of the link paths")
    args = parser.parse_args()

    checked, dead = check_links(Path(args.data_dir), Path(args.site_dir))
    if not dead:
        print(f"All {checked} download links of the PD dashboard resolve")
        return 0
    annotate("warning", f"{len(dead)} of the {checked} download links of the PD dashboard are dead, "
                        f"the dashboard is deployed anyway (list in the step log)")
    for description in dead[:MAX_ANNOTATED]:
        annotate("warning", f"Dead download link: {description}")
    for description in dead[MAX_ANNOTATED:]:
        print(f"Dead download link: {description}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
