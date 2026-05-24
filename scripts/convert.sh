#!/usr/bin/env bash
set -euo pipefail

# OISD lists: URL -> output filename
declare -A LISTS
LISTS["https://big.oisd.nl"]="big.txt"
LISTS["https://small.oisd.nl"]="small.txt"
LISTS["https://nsfw.oisd.nl"]="nsfw.txt"
LISTS["https://nsfw-small.oisd.nl"]="nsfw-small.txt"

# Custom hosts-format lists
LISTS["https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"]="stephen-black-nsfw.txt"

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

    # Try to detect format
    # OISD format: ||domain^
    local oisd_count
    oisd_count=$(grep -cE '^\|\|[^\^]+\^$' "$tmpfile" 2>/dev/null) || true
    if [ -n "$oisd_count" ] && [ "$oisd_count" -gt 0 ]; then
        echo "  Detected OISD format ($oisd_count rules)"
        entries=$(grep -oP '^\|\|([^^]+)\^' "$tmpfile" | sed 's/^||//;s/\^$//' | sort -u || true)
    else
        # Hosts format: 0.0.0.0 domain
        local hosts_count
        hosts_count=$(grep -cE '^[0-9.]+[[:space:]]+' "$tmpfile" 2>/dev/null) || true
        if [ -n "$hosts_count" ] && [ "$hosts_count" -gt 0 ]; then
            echo "  Detected HOSTS format ($hosts_count rules)"
            entries=$(grep -E '^[0-9.]+[[:space:]]+' "$tmpfile" | awk '{print $2}' | sed '/^$/d;/^#/d' | sort -u || true)
        else
            # Fallback: try to extract any domain-like line
            entries=$(grep -oP '([\w-]+\.)+[\w-]+' "$tmpfile" | grep -E '\.' | sort -u || true)
        fi
    fi

    if [ -z "$entries" ]; then
        echo "WARNING: No entries extracted from $url"
        rm -f "$tmpfile"
        return 0
    fi

    echo "$entries" > "$OUTPUT_DIR/$output"

    local count
    count=$(wc -l < "$OUTPUT_DIR/$output")
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
