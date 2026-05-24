#!/usr/bin/env python3
"""Strip subdomains to keep only registered domains (e.g. domain.tld)."""
import argparse
import sys
from pathlib import Path


def strip_subdomains(input_path, output_path):
    try:
        import tldextract
    except ImportError:
        print("ERROR: tldextract is required. Install with: pip install tldextract", file=sys.stderr)
        sys.exit(1)

    domains = set()
    skipped = 0

    with open(input_path, "r", encoding="utf-8") as f:
        for line in f:
            raw = line.strip().lower()
            if not raw:
                continue
            ext = tldextract.extract(raw)
            if ext.domain and ext.suffix:
                domains.add(f"{ext.domain}.{ext.suffix}")
            else:
                # Fallback: keep as-is if tldextract can't parse it
                domains.add(raw)
                skipped += 1

    with open(output_path, "w", encoding="utf-8") as f:
        for d in sorted(domains):
            f.write(f"{d}\n")

    input_count = sum(1 for _ in open(input_path, "r", encoding="utf-8") if _.strip())
    print(f"  {input_path} -> {output_path}: {input_count} -> {len(domains)} domains (stripped {input_count - len(domains)} subdomains)")
    if skipped:
        print(f"  NOTE: {skipped} domains kept as-is because tldextract could not parse them")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Strip subdomains to registered domain level")
    parser.add_argument("--input", required=True, help="Input domain list")
    parser.add_argument("--output", required=True, help="Output path")
    args = parser.parse_args()
    strip_subdomains(args.input, args.output)
