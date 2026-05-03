#!/usr/bin/env python3
"""Generate Gatus config.yml from a CSV file.

Usage:
    python csv2config.py                        # reads endpoints.csv, writes config.yml
    python csv2config.py -i my.csv -o out.yml   # custom paths
    python csv2config.py --dry-run              # print to stdout without writing

CSV columns:
    name              (required) Endpoint name
    group             (optional) Group label for the UI
    type              (required) http | tcp | dns | icmp
    url               (required) Target URL or address
    interval          (required) Check interval (e.g. 30s, 5m)
    conditions        (required) Pipe-separated conditions list
    alert_description (optional) Discord alert message
    dns_query_name    (dns only) Domain to query
    dns_query_type    (dns only) Record type (A, AAAA, CNAME, etc.)
    dns_expected_body (dns only) Expected IP/value in [BODY] condition
"""

import argparse
import csv
import sys
from pathlib import Path

REQUIRED = {"name", "type", "url", "interval", "conditions"}


def parse_row(row: dict) -> dict:
    missing = REQUIRED - {k for k, v in row.items() if v.strip()}
    if missing:
        raise ValueError(f"Missing required columns: {', '.join(sorted(missing))}")

    ep: dict = {
        "name": row["name"].strip(),
        "url": row["url"].strip(),
        "interval": row["interval"].strip(),
        "conditions": [c.strip() for c in row["conditions"].split("|") if c.strip()],
    }

    if row.get("group", "").strip():
        ep["group"] = row["group"].strip()

    check_type = row["type"].strip().lower()

    if check_type == "dns":
        qname = row.get("dns_query_name", "").strip()
        qtype = row.get("dns_query_type", "").strip()
        if not qname or not qtype:
            raise ValueError(f"DNS endpoint '{ep['name']}' requires dns_query_name and dns_query_type")
        ep["dns"] = {"query-name": qname, "query-type": qtype}

    alert_desc = row.get("alert_description", "").strip()
    if alert_desc:
        alert: dict = {"type": "discord", "description": alert_desc}
        if check_type in ("dns", "icmp", "tcp"):
            alert["send-on-resolved"] = True
        ep.setdefault("alerts", []).append(alert)

    return ep


def read_csv(path: str) -> list[dict]:
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        endpoints = []
        for i, row in enumerate(reader, start=2):
            try:
                endpoints.append(parse_row(row))
            except ValueError as e:
                print(f"⚠️  Row {i}: {e}", file=sys.stderr)
    return endpoints


def build_config(endpoints: list[dict]) -> dict:
    return {
        "storage": {"type": "sqlite", "path": "/data/data.db"},
        "alerting": {
            "discord": {
                "webhook-url": "${DISCORD_WEBHOOK_URL}",
                "default-alert": {
                    "failure-threshold": 1,
                    "success-threshold": 2,
                    "send-on-resolved": True,
                    "description": "[ALERT_TRIGGERED_OR_RESOLVED] — [ENDPOINT_NAME] ([ENDPOINT_GROUP])\nURL: [ENDPOINT_URL]\nErrors: [RESULT_ERRORS]",
                },
            }
        },
        "endpoints": endpoints,
    }


def write_yaml(config: dict, path: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(dump_yaml_manual(config))


def dump_yaml_manual(config: dict) -> str:
    lines = []
    lines.append("storage:")
    lines.append("  type: sqlite")
    lines.append('  path: /data/data.db')
    lines.append("")
    lines.append("alerting:")
    lines.append("  discord:")
    lines.append('    webhook-url: "${DISCORD_WEBHOOK_URL}"')
    lines.append("    default-alert:")
    lines.append("      failure-threshold: 1")
    lines.append("      success-threshold: 2")
    lines.append("      send-on-resolved: true")
    lines.append('      description: "[ALERT_TRIGGERED_OR_RESOLVED] - [ENDPOINT_NAME] ([ENDPOINT_GROUP])\\nURL: [ENDPOINT_URL]\\nErrors: [RESULT_ERRORS]"')
    lines.append("")
    lines.append("endpoints:")
    for ep in config.get("endpoints", []):
        lines.append(f"  - name: {ep['name']}")
        if "group" in ep:
            lines.append(f"    group: {ep['group']}")
        lines.append(f"    url: \"{ep['url']}\"")
        lines.append(f"    interval: {ep['interval']}")
        if "dns" in ep:
            lines.append("    dns:")
            lines.append(f"      query-name: \"{ep['dns']['query-name']}\"")
            lines.append(f"      query-type: \"{ep['dns']['query-type']}\"")
        lines.append("    conditions:")
        for c in ep["conditions"]:
            lines.append(f'      - "{c}"')
        if "alerts" in ep:
            lines.append("    alerts:")
            for a in ep["alerts"]:
                lines.append(f"      - type: {a['type']}")
                desc = a["description"]
                lines.append(f'        description: "{desc}"')
                if a.get("send-on-resolved"):
                    lines.append("        send-on-resolved: true")
        lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate Gatus config.yml from CSV")
    parser.add_argument("-i", "--input", default="endpoints.csv", help="Input CSV file (default: endpoints.csv)")
    parser.add_argument("-o", "--output", default="config.yml", help="Output YAML file (default: config.yml)")
    parser.add_argument("--dry-run", action="store_true", help="Print YAML to stdout without writing a file")
    args = parser.parse_args()

    csv_path = Path(args.input)
    if not csv_path.exists():
        print(f"Error: {csv_path} not found", file=sys.stderr)
        sys.exit(1)

    endpoints = read_csv(str(csv_path))
    if not endpoints:
        print("No valid endpoints found in CSV.", file=sys.stderr)
        sys.exit(1)

    config = build_config(endpoints)

    if args.dry_run:
        print(dump_yaml_manual(config))
    else:
        write_yaml(config, args.output)
        print(f"Generated {args.output} with {len(endpoints)} endpoint(s)")


if __name__ == "__main__":
    main()
