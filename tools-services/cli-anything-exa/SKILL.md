---
name: "cli-anything-exa"
description: >-
  Agent-native CLI for Exa web search and content retrieval workflows.
---

# Exa CLI Skill

Agent-native CLI for the **Exa** neural search API: web search across modes plus full-text or
highlighted page contents. Entry point `cli-anything-exa`, v1.0.0.

## Setup

Needs Python >= 3.10.

<!-- security: install ONLY via cli-hub or the git+ URL below — the bare PyPI name is unregistered (dependency-confusion risk), see ATTRIBUTION.md -->
```bash
cli-hub install exa
# or, direct from source:
pip install git+https://github.com/HKUDS/CLI-Anything.git#subdirectory=exa/agent-harness

export EXA_API_KEY="…"                  # https://dashboard.exa.ai/api-keys
cli-anything-exa server status          # verify key + connectivity
```

## Commands

```bash
cli-anything-exa [--json] search "<query>" [OPTIONS]
  --type       auto|fast|instant|deep|deep-reasoning  (default: auto)
  --num-results / -n   1–100  (default: 10)
  --category   company|people|research-paper|news|personal-site|financial-report
  --content    highlights|text|summary|none  (default: highlights)
  --freshness  smart|always|never  (default: smart)
  --include-domains / --exclude-domains DOMAIN   (repeatable)
  --from / --to DATE   ISO 8601 published-date range
  --location CC        two-letter country code, geo-bias

cli-anything-exa [--json] contents <url> [url ...] [--content …] [--freshness …]
```

`--json` is a root-level flag (before the subcommand); no subcommand enters a REPL.

## Notes

- `highlights` content mode is 10× more token-efficient than `text` — prefer it for agent pipelines
- `--type deep` triggers multi-step reasoning; slower but synthesises across many sources
- `--category company` and `--category people` do not support date or domain-exclude filters
- Cost per query is included in JSON output under `cost_dollars`
