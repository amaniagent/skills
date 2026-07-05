# Attribution — vendored skill

Vendored from an external project (not authored by amaniagent), audit-gated per our policy.

| | |
|---|---|
| **Source** | https://github.com/agent0ai/CLI-Anything (HKUDS/CLI-Anything) |
| **Path upstream** | `skills/cli-anything-obsidian/SKILL.md` |
| **Author** | CLI-Anything Team (HKUDS) and contributors |
| **License** | Apache-2.0 — see `LICENSE` in this folder (retained per the license terms) |
| **Modifications** | None — the `SKILL.md` is copied verbatim. |
| **Vendored** | 2026-07-05 |
| **Security audit** | skill-auditor **0/8 (safe)** — pure documentation; no scripts, network egress, shell, or fs-writes in the SKILL.md itself. See `~/agents/claude/sessions/skill-discovery-audits.md`. |

## What it needs / where data goes
Requires the `cli-anything-obsidian` CLI (via cli-hub) and Obsidian running with its **Local REST API** plugin. Talks to your local Obsidian only — no external egress.

## Why vendored
Selective vendoring (Jay, 2026-07-05): a genuinely useful, standalone tool-driving skill that fits
our stack. Drive the tool via its `cli-anything-obsidian` harness (install with `cli-hub install obsidian`);
see the `use-cli-anything` skill for the cli-hub model.
