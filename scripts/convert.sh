#!/usr/bin/env bash
set -euo pipefail

# OISD lists: URL -> output filename
declare -A LISTS
LISTS["https://big.oisd.nl"]="big.txt"
LISTS["https://small.oisd.nl"]="small.txt"
LISTS["https://nsfw.oisd.nl"]="nsfw.txt"
LISTS["https://nsfw-small.oisd.nl"]="nsfw-small.txt"

OUTPUT_DIR="${1:-lists}"

mkdir -p "$OUTPUT_DIR"

convert_list() {
    local url="$1"
    local output="$2"
    local tmpfile
    tmpfile=$(mktemp)

    echo "Fetching $url ..."
    if ! curl -sL --max-time 60 "$url" > "$tmpfile"; then
        echo "ERROR: Failed to fetch $url"
        rm -f "$tmpfile"
        return 1
    fi

    local entries
    entries=$(grep -oP '^\|\|([^^]+)\^' "$tmpfile" | sed 's/^||//;s/\^$//' | sort -u || true)

    if [ -z "$entries" ]; then
        # Fallback: try to extract any line matching ||something^
        entries=$(grep -E '^\|\|.+\^$' "$tmpfile" | sed 's/^||//;s/\^$//' | sort -u || true)
    fi

    echo "$entries" > "$OUTPUT_DIR/$output"

    local count
    count=$(echo "$entries" | wc -l)
    echo "  -> $OUTPUT_DIR/$output ($count domains)"

    rm -f "$tmpfile"
}

for url in "${!LISTS[@]}"; do
    convert_list "$url" "${LISTS[$url]}"
done

echo "Done. All lists saved to $OUTPUT_DIR/"
echo ""
echo "File sizes:"
wc -l "$OUTPUT_DIR"/*.txt
