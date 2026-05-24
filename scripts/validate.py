#!/usr/bin/env python3
"""DNS validation for domain lists (system resolver via socket.getaddrinfo)."""

import argparse
import concurrent.futures
import json
import os
import socket
import sys
import time
from pathlib import Path


def read_domains(path):
    with open(path, "r", encoding="utf-8") as f:
        return {line.strip().lower() for line in f if line.strip()}


def write_domains(path, domains):
    with open(path, "w", encoding="utf-8") as f:
        for d in sorted(domains):
            f.write(f"{d}\n")


def check_domain(domain):
    """Return True if socket.getaddrinfo succeeds (domain has A/AAAA records)."""
    try:
        socket.getaddrinfo(domain, None)
        return domain, True
    except socket.gaierror as e:
        if e.errno in (socket.EAI_NONAME, socket.EAI_NODATA, -5, -2):
            return domain, False
    except Exception:
        pass
    return domain, False


def validate_domains(domains, max_workers):
    total = len(domains)
    completed = 0
    results = {}
    report_every = max(total // 20, 100)
    next_report = report_every
    start = time.time()

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_domain = {executor.submit(check_domain, d): d for d in domains}
        for future in concurrent.futures.as_completed(future_to_domain):
            domain, active = future.result()
            results[domain] = active
            completed += 1
            if completed >= next_report:
                elapsed = time.time() - start
                qps = completed / elapsed if elapsed else 0
                sys.stderr.write(f"  ... {completed}/{total} ({completed/total*100:.1f}%) @ {qps:.0f} qps\n")
                next_report += report_every

    return results


def run_full(source, output_active, output_inactive, max_workers):
    print(f"Reading domains from {source}...")
    raw = read_domains(source)

    if not raw:
        print(f"WARNING: No domains found in {source}")
        write_domains(output_active, set())
        write_domains(output_inactive, set())
        write_stats(output_active, 0, 0, 0, 0.0)
        return

    print(f"Validating {len(raw)} domains with max_workers={max_workers}...")
    start = time.time()
    results = validate_domains(list(raw), max_workers)
    duration = time.time() - start

    active = {d for d, ok in results.items() if ok}
    inactive = {d for d, ok in results.items() if not ok}

    print(f"  Active: {len(active)}, Inactive: {len(inactive)} ({duration:.1f}s)")

    write_domains(output_active, active)
    write_domains(output_inactive, inactive)
    write_stats(output_active, len(raw), len(active), len(inactive), duration)


def run_incremental(source, active_path, inactive_path, letter, max_workers):
    print(f"Reading source {source}...")
    raw = read_domains(source)
    active = read_domains(active_path) if os.path.exists(active_path) else set()
    inactive = read_domains(inactive_path) if os.path.exists(inactive_path) else set()

    active = active & raw
    inactive = inactive & raw

    new_domains = raw - active - inactive

    def matches_letter(d):
        if not d:
            return False
        if letter == "0":
            return d[0].isdigit()
        return d.startswith(letter)

    review_active = {d for d in active if matches_letter(d)}
    review_inactive = {d for d in inactive if matches_letter(d)}
    review = review_active | review_inactive

    to_validate = list(new_domains | review)

    print(
        f"New: {len(new_domains)}, Review ({letter}): {len(review)} "
        f"(active={len(review_active)}, inactive={len(review_inactive)})"
    )
    print(f"Total to validate: {len(to_validate)} with max_workers={max_workers}...")

    if not to_validate:
        print("Nothing to validate.")
        write_domains(active_path, active)
        write_domains(inactive_path, inactive)
        write_stats(active_path, len(raw), len(active), len(inactive), 0.0)
        return

    start = time.time()
    results = validate_domains(to_validate, max_workers)
    duration = time.time() - start

    for d, ok in results.items():
        if ok:
            active.add(d)
            inactive.discard(d)
        else:
            inactive.add(d)
            active.discard(d)

    print(f"  Active: {len(active)}, Inactive: {len(inactive)} ({duration:.1f}s)")

    write_domains(active_path, active)
    write_domains(inactive_path, inactive)
    write_stats(active_path, len(raw), len(active), len(inactive), duration)


def write_stats(base_path, total, active_count, inactive_count, duration):
    stats = {
        "total_raw": total,
        "active": active_count,
        "inactive": inactive_count,
        "duration_seconds": round(duration, 1),
    }
    stats_path = str(Path(base_path).with_suffix("")) + ".json"
    with open(stats_path, "w", encoding="utf-8") as f:
        json.dump(stats, f, indent=2)


def main():
    parser = argparse.ArgumentParser(description="DNS validation for domain lists")
    parser.add_argument("--mode", choices=["full", "incremental"], required=True)
    parser.add_argument("--source", required=True, help="Input domain list")
    parser.add_argument("--output-active", help="Output active list (full mode)")
    parser.add_argument("--output-inactive", help="Output inactive list (full mode)")
    parser.add_argument("--active", help="Existing active list (incremental mode)")
    parser.add_argument("--inactive", help="Existing inactive list (incremental mode)")
    parser.add_argument("--letter", help="Letter to review (incremental mode)")
    parser.add_argument("--max-workers", type=int, default=40)
    args = parser.parse_args()

    if args.mode == "full":
        if not args.output_active or not args.output_inactive:
            parser.error("--output-active and --output-inactive required for full mode")
        run_full(args.source, args.output_active, args.output_inactive, args.max_workers)
    else:
        if not args.active or not args.inactive or not args.letter:
            parser.error("--active, --inactive, and --letter required for incremental mode")
        run_incremental(args.source, args.active, args.inactive, args.letter, args.max_workers)


if __name__ == "__main__":
    main()
