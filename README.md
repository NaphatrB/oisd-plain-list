# OISD Plain Domain Lists

Plain-text domain lists converted from [OISD](https://oisd.nl) for use with GL.iNet routers (VPN Policy, Parental Control rulesets).

## Lists

| File | Source | Domains | Size | Best for |
|------|--------|---------|------|----------|
| [`big.txt`](lists/big.txt) | [big.oisd.nl](https://big.oisd.nl) | ~406k | 8.1 MB | High-RAM routers, aggressive blocking |
| [`small.txt`](lists/small.txt) | [small.oisd.nl](https://small.oisd.nl) | ~57k | 1.1 MB | General purpose (recommended) |
| [`nsfw.txt`](lists/nsfw.txt) | [nsfw.oisd.nl](https://nsfw.oisd.nl) | ~354k | 6.3 MB | Adult content blocking, high-RAM routers |
| [`nsfw-small.txt`](lists/nsfw-small.txt) | [nsfw-small.oisd.nl](https://nsfw-small.oisd.nl) | ~17k | 246 KB | Adult content blocking (recommended) |

## GL.iNet Subscription URLs

Paste these into your router's VPN Policy or Parental Control → Ruleset:

```
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/big.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/small.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/nsfw.txt
https://raw.githubusercontent.com/NaphatrB/oisd-plain-list/main/lists/nsfw-small.txt
```

## How it works

A GitHub Action runs daily at 3AM UTC (or manually via `workflow_dispatch`) that:

1. Fetches each OISD list (Adblock Plus format: `||domain^`)
2. Strips the `||` prefix and `^` suffix
3. Sorts and deduplicates
4. Commits the plain lists back to this repo

The conversion is lossless — OISD only uses domain-level blocking, so no information is lost.

## Credits

All lists sourced from [oisd.nl](https://oisd.nl) by Stephan van Ruth.
