#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Convert raw lists
bash scripts/convert.sh lists

echo "Validation skipped (DNS lookup disabled)."

echo ""
echo "Update complete."
