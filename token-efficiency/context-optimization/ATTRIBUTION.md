# Attribution — vendored skill

This skill is **vendored from an external project**, not authored by amaniagent.

| | |
|---|---|
| **Source** | https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering |
| **Path upstream** | `skills/context-optimization/SKILL.md` |
| **Author** | Muratcan Koylan and contributors (frontmatter: "Context Engineering Agent Skills Contributors") |
| **License** | MIT — see `LICENSE` in this folder (retained per the license terms) |
| **Vendored** | 2026-07-04 |
| **Security audit** | skill-auditor **0/8 (safe)** — pure text/analysis; no scripts, network, shell, or filesystem writes. The Python blocks are illustrative snippets in the prose, not shipped executables. See `~/agents/claude/sessions/skill-discovery-audits.md`. |

## Why vendored (and not rebuilt)

Per the "vendor excellent external skills, attributed" policy: this is a strong, well-measured
treatment of context-optimization theory (KV-cache, observation masking, compaction thresholds,
partitioning) with concrete performance targets and gotchas. Rather than paraphrase it, we vendor
it verbatim with attribution.

## Relationship to our own token-efficiency skills

- `context-thrift` (ours) — the same tactics **grounded in our concrete tooling** (gcx/toon wire
  formats, `compress_bodies` body-elision, gortex retrieval). Reach for it first in our stack.
- `context-optimization` (this, vendored) — the **canonical, tool-agnostic theory** with
  measurement targets. Read it for the deeper "why" and the numeric targets.

## Note

The upstream skill references an optional `references/optimization_techniques.md` deep-dive that we
did **not** vendor; get it from the source repo above. The canonical, byte-exact version of this
SKILL.md also lives upstream — this copy is for offline catalog use.
