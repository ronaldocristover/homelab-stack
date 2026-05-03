#!/usr/bin/env python3
"""Generate CSV rows for csv2config.py from a simple project YAML definition.

Input YAML format:
    project: hkccc-dev
    interval: 5m
    services:
      portal: hkccc-dev-portal.gbempower.asia
      api: hkccc-dev-api.gbempower.asia
      admin: hkccc-dev-admin.gbempower.asia

Each service produces one CSV row:
    name = {project}-{service}
    group = {project}
    type = http
    url = https://{domain}
    interval = from YAML or 5m default
    conditions = [STATUS] == 200
    alert_description = auto-generated

Usage:
    python project2csv.py -i projects/hkccc-dev.yml
    python project2csv.py -i projects/hkccc-dev.yml -o endpoints.csv
    python project2csv.py -i projects/hkccc-dev.yml --dry-run
    python project2csv.py -i projects/hkccc-dev.yml -a              # append to existing CSV
"""

import argparse
import csv
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Error: PyYAML is required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

FIELDS = [
    "name", "group", "type", "url", "interval",
    "conditions", "alert_description",
    "dns_query_name", "dns_query_type", "dns_expected_body",
]


def load_project(path: str) -> dict:
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if "project" not in data:
        raise ValueError("Missing 'project' key")
    if "services" not in data or not data["services"]:
        raise ValueError("Missing or empty 'services' key")
    return data


def build_rows(data: dict) -> list[dict]:
    project = data["project"]
    interval = data.get("interval", "60s")
    protocol = data.get("protocol", "https")
    description_template = data.get(
        "alert_description",
        "\u26a0\ufe0f **{name} Unreachable** \u2014 HTTP check to {url} returned non-200 (group: {group})",
    )
    rows = []
    for service, domain in data["services"].items():
        name = f"{project}-{service}"
        url = f"{protocol}://{domain}"
        desc = description_template.format(name=name, url=url, group=project)
        rows.append({
            "name": name,
            "group": project,
            "type": "http",
            "url": url,
            "interval": interval,
            "conditions": "[STATUS] == 200",
            "alert_description": desc,
            "dns_query_name": "",
            "dns_query_type": "",
            "dns_expected_body": "",
        })
    return rows


def write_csv(rows: list[dict], path: str, append: bool = False) -> None:
    file_exists = Path(path).exists() and Path(path).stat().st_size > 0
    mode = "a" if append and file_exists else "w"
    with open(path, mode, newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        if not (append and file_exists):
            writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description="Generate CSV rows from project YAML")
    parser.add_argument("-i", "--input", required=True, help="Input YAML file")
    parser.add_argument("-o", "--output", default="endpoints.csv", help="Output CSV file (default: endpoints.csv)")
    parser.add_argument("-a", "--append", action="store_true", help="Append to existing CSV instead of overwriting")
    parser.add_argument("--dry-run", action="store_true", help="Print CSV rows to stdout")
    args = parser.parse_args()

    data = load_project(args.input)
    rows = build_rows(data)

    if args.dry_run:
        writer = csv.DictWriter(sys.stdout, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    else:
        write_csv(rows, args.output, append=args.append)
        action = "Appended" if args.append else "Wrote"
        print(f"{action} {len(rows)} row(s) to {args.output}")


if __name__ == "__main__":
    main()
