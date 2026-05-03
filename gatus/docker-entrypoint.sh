#!/bin/sh
set -e

CONFIG_DIR="/config"
CSV_FILE="${CONFIG_DIR}/endpoints.csv"
CONFIG_FILE="${CONFIG_DIR}/config.yml"

if [ -f "$CSV_FILE" ]; then
    echo "Generating config.yml from endpoints.csv..."
    python3 /scripts/csv2config.py -i "$CSV_FILE" -o "$CONFIG_FILE"
    echo "Done."
else
    echo "No endpoints.csv found, using existing config.yml as-is."
fi

exec "$@"
