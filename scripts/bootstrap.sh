#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

VENV=".venv"
if [ ! -d "$VENV" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV"
fi
source "$VENV/bin/activate"

if ! python3 -c "import requests" 2>/dev/null; then
    echo "Installing dependencies..."
    pip install requests[socks]
fi

echo "Converting OISD lists..."
bash scripts/convert.sh lists

for list in big small nsfw nsfw-small stephen-black-nsfw; do
    echo ""
    echo "=== Bootstrapping ${list} ==="
    python3 scripts/validate.py --mode full \
        --source "lists/${list}.txt" \
        --output-active "lists/${list}-active.txt" \
        --output-inactive "lists/${list}-inactive.txt" \
        --max-workers "${BOOTSTRAP_WORKERS:-40}"
done

echo ""
echo "Bootstrap complete."
