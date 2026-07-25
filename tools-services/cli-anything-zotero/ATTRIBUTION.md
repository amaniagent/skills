# Attribution — vendored skill

Vendored from an external project (not authored by amaniagent), audit-gated per our policy.

| | |
|---|---|
| **Source** | https://github.com/HKUDS/CLI-Anything (moved from agent0ai/CLI-Anything, which 404s as of 2026-07-25; confirmed same project via identical `skills/` layout and file paths) |
| **Path upstream** | `skills/cli-anything-zotero/SKILL.md` |
| **Author** | CLI-Anything Team (HKUDS) and contributors |
| **License** | Apache-2.0 — see `LICENSE` in this folder (retained per the license terms) |
| **Modifications** | None — the `SKILL.md` is copied verbatim. |
| **Vendored** | 2026-07-05 |
| **Security audit** | skill-auditor **0/8 (safe)** — pure documentation; no scripts, network egress, shell, or fs-writes in the SKILL.md itself. See `~/agents/claude/sessions/skill-discovery-audits.md`. |

## What it needs / where data goes
Requires the `cli-anything-zotero` CLI (via cli-hub) and a running Zotero (local API). Local — no external egress.

## Why vendored
Selective vendoring (Jay, 2026-07-05): a genuinely useful, standalone tool-driving skill that fits
our stack. Drive the tool via its `cli-anything-zotero` harness (install with `cli-hub install zotero`);
see the `use-cli-anything` skill for the cli-hub model.
