# Attribution — vendored skill

Vendored from an external project (not authored by amaniagent), audit-gated per our policy.

| | |
|---|---|
| **Source** | https://github.com/HKUDS/CLI-Anything (moved from agent0ai/CLI-Anything, which 404s as of 2026-07-25; confirmed same project via identical `skills/` layout and file paths) |
| **Path upstream** | `skills/cli-anything-exa/SKILL.md` |
| **Author** | CLI-Anything Team (HKUDS) and contributors |
| **License** | Apache-2.0 — see `LICENSE` in this folder (retained per the license terms) |
| **Modifications** | Adapted — (1) a security comment added above the install command, flagging the package name as unregistered on PyPI (dependency-confusion risk, see below); (2) **shortened 2026-07-25 (see repo history for full version)** — the generated command reference and the worked search examples were condensed; flags, defaults and the agent notes are kept. |
| **Vendored** | 2026-07-05 |
| **Security audit** | skill-auditor **0/8 (safe)** — pure documentation; no scripts, network egress, shell, or fs-writes in the SKILL.md itself. See `~/agents/claude/sessions/skill-discovery-audits.md`. |

## Added security comment
The `SKILL.md` in this folder has one inline HTML comment added above the install command,
flagging that the upstream package name is unregistered on PyPI (dependency-confusion risk) —
do not `pip install` it directly, use `cli-hub install` instead.

## What it needs / where data goes
Requires the `cli-anything-exa` CLI (install via cli-hub) **and** an Exa API key (`EXA_API_KEY`). Calls the external **Exa API** (dashboard.exa.ai) — search queries + your key go to Exa.

## Why vendored
Selective vendoring (Jay, 2026-07-05): a genuinely useful, standalone tool-driving skill that fits
our stack. Drive the tool via its `cli-anything-exa` harness (install with `cli-hub install exa`);
see the `use-cli-anything` skill for the cli-hub model.
