# OISD Plain Domain Lists

Plain-text domain lists converted from [OISD](https://oisd.nl) and other curated sources for use with GL.iNet routers, AdGuard Home, Pi-hole, and other DNS-level ad blockers.

## Lists

| File | Source | Domains | Size | Best for |
|------|--------|---------|------|----------|
| [`big.txt`](lists/big.txt) | [big.oisd.nl](https://big.oisd.nl) | 328,135 | 6.4 MB | High-RAM routers, aggressive blocking |
| [`small.txt`](lists/small.txt) | [small.oisd.nl](https://small.oisd.nl) | 57,361 | 1.1 MB | General purpose (recommended) |
| [`nsfw.txt`](lists/nsfw.txt) | [nsfw.oisd.nl](https://nsfw.oisd.nl) | 361,274 | 6.4 MB | Adult content blocking |
| [`nsfw-small.txt`](lists/nsfw-small.txt) | [nsfw-small.oisd.nl](https://nsfw-small.oisd.nl) | 17,184 | 248 KB | Adult content blocking, compact (recommended) |

### Custom NSFW Lists

Curated third-party blocklists converted to plain domain format:

| File | Source | Domains | Size | Best for |
|------|--------|---------|------|----------|
| [`stephen-black-nsfw.txt`](lists/stephen-black-nsfw.txt) | [StevenBlack/hosts](https://github.com/StevenBlack/hosts) | 76,722 | 1.3 MB | StevenBlack porn-only blocklist |
| [`bon-appetite-nsfw.txt`](lists/bon-appetite-nsfw.txt) | [Bon-Appetit/porn-domains](https://github.com/Bon-Appetit/porn-domains) | 698,132 | 14 MB | Comprehensive, frequently updated |

### Registered-Domain-Only (XSmall) Variants

Strips subdomains to keep only `<domain>.<tld>`, making lists smaller for routers that block subdomains automatically (e.g. `www.example.com` → `example.com`):

| File | Source | Domains | Size | Description |
|------|--------|---------|------|-------------|
| [`bon-appetite-nsfw-xsmall.txt`](lists/bon-appetite-nsfw-xsmall.txt) | bon-appetite-nsfw.txt | 398,023 | 6.0 MB | ~43% smaller than `bon-appetite-nsfw.txt` |

## GL.iNet Subscription URLs

Paste these into your router's **VPN Policy** or **Parental Control → Ruleset**:

```
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/big.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/small.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/nsfw.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/nsfw-small.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/stephen-black-nsfw.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/bon-appetite-nsfw.txt
```

Or the smaller **xsmall** variants (recommended for GL.iNet with limited RAM):

```
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/nsfw-xsmall.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/bon-appetite-nsfw-xsmall.txt
```

## How it works

A GitHub Action runs daily at 3AM UTC (or manually via `workflow_dispatch`) that:

1. Fetches each OISD list (Adblock Plus format: `||domain^`)
2. Strips the `||` prefix and `^` suffix; converts HOSTS-format lists to plain domain lists
3. Sorts and deduplicates
4. Generates **xsmall** (registered-domain-only) variants from NSFW lists
5. Commits the plain lists back to this repo

The conversion is lossless — all sources only use domain-level blocking, so no information is lost.

## Credits

- [oisd.nl](https://oisd.nl) by Stephan van Ruth — OISD blocklists
- [StevenBlack/hosts](https://github.com/StevenBlack/hosts) — StevenBlack curated hosts
- [Bon-Appetit/porn-domains](https://github.com/Bon-Appetit/porn-domains) — Comprehensive porn-domains blocklist
