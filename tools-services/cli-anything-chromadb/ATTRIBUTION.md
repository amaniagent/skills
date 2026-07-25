# Attribution — vendored skill

Vendored from an external project (not authored by amaniagent), audit-gated per our policy.

| | |
|---|---|
| **Source** | https://github.com/HKUDS/CLI-Anything (moved from agent0ai/CLI-Anything, which 404s as of 2026-07-25; confirmed same project via identical `skills/` layout and file paths) |
| **Path upstream** | `skills/cli-anything-chromadb/SKILL.md` |
| **Author** | CLI-Anything Team (HKUDS) and contributors |
| **License** | Apache-2.0 — see `LICENSE` in this folder (retained per the license terms) |
| **Modifications** | Adapted — one line added above the install command: a security comment flagging the package name as unregistered on PyPI (dependency-confusion risk, see below). Otherwise verbatim upstream. |
| **Vendored** | 2026-07-05 |
| **Security audit** | skill-auditor **0/8 (safe)** — pure documentation; no scripts, network egress, shell, or fs-writes in the SKILL.md itself. See `~/agents/claude/sessions/skill-discovery-audits.md`. |

## Added security comment
The `SKILL.md` in this folder has one inline HTML comment added above the install command,
flagging that the upstream package name is unregistered on PyPI (dependency-confusion risk) —
do not `pip install` it directly, use `cli-hub install` instead. Everything else is verbatim
upstream.

## What it needs / where data goes
Requires the `cli-anything-chromadb` CLI (via cli-hub) and a running **ChromaDB** server (HTTP API v2). Talks to the ChromaDB endpoint you point it at; no other egress.

## Why vendored
Selective vendoring (Jay, 2026-07-05): a genuinely useful, standalone tool-driving skill that fits
our stack. Drive the tool via its `cli-anything-chromadb` harness (install with `cli-hub install chromadb`);
see the `use-cli-anything` skill for the cli-hub model.
