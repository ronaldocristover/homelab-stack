#!/bin/sh
set -e

CONFIG_DIR="/config"
CSV_FILE="${CONFIG_DIR}/endpoints.csv"
CONFIG_FILE="${CONFIG_DIR}/config.yml"

if [ -f "$CSV_FILE" ]; then
    echo "Generating config.yml from endpoints.csv..."
    python3 /scripts/csv2config.py -i "$CSV_FILE" -o "$CONFIG_FILE"
    echo "Done."
    exec "$@"
else
    echo "WARNING: No endpoints.csv found."
    echo "Generate endpoints.csv first, then restart:"
    echo "  python3 /scripts/project2csv.py -i /config/projects/<project>.yml -o /config/endpoints.csv"
    echo "  docker compose restart gatus"
    echo ""
    echo "Sleeping indefinitely. Container is ready but Gatus is not running."
    tail -f /dev/null
fi
