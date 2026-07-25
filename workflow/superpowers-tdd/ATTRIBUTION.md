# Attribution — vendored skill

Vendored from an external project (not authored by amaniagent), audit-gated per our policy.

| | |
|---|---|
| **Source** | https://github.com/obra/superpowers |
| **Skill** | test-driven-development |
| **Author** | Jesse Vincent (obra) & contributors |
| **License** | MIT — see `LICENSE` in this folder (retained per the license terms) |
| **Modifications** | `SKILL.md` **shortened 2026-07-25 (see repo history for full version)** — the rules stated three times over were folded into one pass and the Graphviz cycle diagram removed. The Iron Law and the rationalizations table are kept; the "Why Order Matters" essay and the worked bug-fix example were compressed into a few lines, so some of their phrasing is gone. `testing-anti-patterns.md` is verbatim. |
| **Vendored** | 2026-07-05 |
| **Security audit** | skill-auditor **0/8 (safe)** — pure prompt/documentation; no scripts, network, shell, or fs-writes beyond your own project. See `~/agents/claude/sessions/skill-discovery-audits.md`. |

## Notes
Single self-contained skill EXCERPTED from the Superpowers framework — the framework's `hooks/`, `scripts/` and other skills are NOT vendored. The skill only reads/writes within your own project.

## Why vendored
Selective vendoring (Jay, 2026-07-05) into the new `workflow/` category — dev-workflow discipline skills
that make an agent plan, question, and test before writing code.
