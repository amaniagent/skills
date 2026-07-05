# Attribution — vendored skill

Vendored from an external project (not authored by amaniagent), audit-gated per our policy.

| | |
|---|---|
| **Source** | https://github.com/mattpocock/skills |
| **Skill** | grilling / Grill Me |
| **Author** | Matt Pocock |
| **License** | MIT — see `LICENSE` in this folder (retained per the license terms) |
| **Modifications** | None — the skill files are copied verbatim. |
| **Vendored** | 2026-07-05 |
| **Security audit** | skill-auditor **0/8 (safe)** — pure prompt/documentation; no scripts, network, shell, or fs-writes beyond your own project. See `~/agents/claude/sessions/skill-discovery-audits.md`. |

## Notes
A relentless spec/design interview. Upstream splits it into `grill-me` (slash trigger) + `grilling` (the interview skill); this is the self-contained `grilling` content.

## Why vendored
Selective vendoring (Jay, 2026-07-05) into the new `workflow/` category — dev-workflow discipline skills
that make an agent plan, question, and test before writing code.
