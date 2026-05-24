#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Convert raw lists
bash scripts/convert.sh lists

# Check if bootstrap is needed
need_bootstrap=false
for list in big small nsfw nsfw-small stephen-black-nsfw bon-appetite-nsfw; do
    if [ ! -f "lists/${list}-active.txt" ]; then
        need_bootstrap=true
        break
    fi
done

if [ "$need_bootstrap" = true ]; then
    echo "Active lists missing; running full validation..."
    for list in big small nsfw nsfw-small stephen-black-nsfw bon-appetite-nsfw nsfw-xsmall bon-appetite-nsfw-xsmall; do
        echo ""
        echo "=== Full validation for ${list} ==="
        python3 scripts/validate.py --mode full \
            --source "lists/${list}.txt" \
            --output-active "lists/${list}-active.txt" \
            --output-inactive "lists/${list}-inactive.txt" \
            --concurrency "${BOOTSTRAP_CONCURRENCY:-200}"
    done
else
    letter=$(cat .last-validated-letter)
    echo "Running incremental validation for letter: $letter"
    for list in big small nsfw nsfw-small stephen-black-nsfw bon-appetite-nsfw nsfw-xsmall bon-appetite-nsfw-xsmall; do
        echo ""
        echo "=== Incremental ${list} (letter ${letter}) ==="
        python3 scripts/validate.py --mode incremental \
            --source "lists/${list}.txt" \
            --active "lists/${list}-active.txt" \
            --inactive "lists/${list}-inactive.txt" \
            --letter "$letter" \
            --concurrency "${INCREMENTAL_CONCURRENCY:-50}"
    done

    # Rotate letter: a -> b -> ... -> z -> 0 -> a
    python3 -c "
letters = 'abcdefghijklmnopqrstuvwxyz0'
current = open('.last-validated-letter').read().strip()
idx = letters.index(current)
next_letter = letters[(idx + 1) % len(letters)]
open('.last-validated-letter', 'w').write(next_letter)
print(f'Rotated validation letter: {current} -> {next_letter}')
"
fi

echo ""
echo "Update complete."
