# amaniagent / skills

Security & tooling skills for AI coding agents (Claude Code, Cursor, Codex, …),
organized by category. Each skill is one folder with a `SKILL.md`.

## Why this exists — the 93 % problem

Reportedly, ~93 % of permission prompts in agentic coding tools get confirmed. That's not
control — that's click fatigue. Every dialog is a mini-meeting the human attends without
context. The alternative isn't *more* prompts, and it isn't auto-approving everything either.

It's **policy instead of popups**: agree on the rules once, in daylight, with a clear head —
what an agent may never do, what needs an explicit sign-off, what is free — and then verify
where verification actually works: **in readable traces afterwards**, not in dialog number 47
of the day. These skills are that policy layer: auditors that vet skills, repos, dependencies,
MCP servers, agent configs and agent *answers* before you trust them, each with
evidence-anchored scores instead of vibes. Built and used daily in a real one-human,
many-agents setup.

## Categories

### 🛡️ security/
Skills that vet other skills, repos, and agent output before you trust them. All score on
the **same 0–8 danger scale** — evidence-anchored, fair, non-alarmist (they score *capability*
and name the likely *intent* separately).

| Skill | Audits |
|-------|--------|
| [**security/skill-auditor**](security/skill-auditor/) | a single agent skill / plugin / MCP |
| [**security/repo-auditor**](security/repo-auditor/) | a whole GitHub repo / package (install scripts, CI, secrets, deps) |
| [**security/answer-verifier**](security/answer-verifier/) | an agent's *answer / output* — hallucination, fabricated sources, invented IDs, "done" claims with no artifact |
| [**security/dependency-auditor**](security/dependency-auditor/) | a project's *dependencies* — lockfile/pinning, typosquat, dependency confusion, install-redirect, malicious install scripts |
| [**security/mcp-auditor**](security/mcp-auditor/) | an *MCP server* — tool scopes, injection in tool descriptions, arg-exfil, over-permissioned config |
| [**security/prompt-injection-detector**](security/prompt-injection-detector/) | *untrusted content* an agent ingests (web/doc/email/RAG) — embedded & hidden prompt injection |
| [**security/settings-auditor**](security/settings-auditor/) | *shipped agent config* — `.claude/settings.json` hooks that auto-run, permission rules that bypass the human prompt |

*(more categories — token-efficiency, rag, memory, tools — coming as they're built.)*

## Install

**Manual (works with any agent — always correct):**
```bash
git clone https://github.com/amaniagent/skills
cp -r skills/security/skill-auditor ~/.claude/skills/   # or your agent's skills dir
```

**Marketplace installer** (installs the whole repo; per-tool syntax varies):
```bash
npx skills add amaniagent/skills        # skills.sh CLI
# or:  npx add-skill amaniagent/skills
```

Then in your agent: *"audit this skill"* / *"audit this repo"* / *"verify this answer"* /
*"audit these dependencies"* / *"audit this MCP server"* / *"scan this for prompt injection"* /
*"audit this settings.json"* triggers the matching auditor.

## The 0–8 scale

`0` safe · `1` benign · `2` low · `3` notable · `4` elevated · `5` risky · `6` dangerous ·
`7` hostile · `8` extremely malicious. **Score = highest band with confirmed file:line evidence.**

A skill or repo can look *green* (popular, reputable author) yet carry a wide, undisclosed
capability surface. These auditors make it visible without falsely branding the author
malicious. A `4/8` means "adopt with mitigation X," not "forbidden."

`answer-verifier` scores the same 0–8 shape on a parallel **confabulation-severity** axis
(`0` grounded → `8` wholesale confabulation) — same evidence discipline (every claim → a source,
or `UNVERIFIABLE`), applied to *output* instead of *code*.

### The verdict layer (two projections of the score)

The 0–8 stays the ground truth; every auditor also emits two deterministic projections of it, so
you can consume the result at the altitude you need:

| SCORE | **GATE** (binary, for automation) | **LEVEL** (graded, for humans) |
|-------|-----------------------------------|--------------------------------|
| 0–2   | `PASS` | `OK` |
| 3–4   | `FLAG` | `RISK` |
| 5–6   | `FLAG` | `HIGH-RISK` |
| 7–8   | `FLAG` | `ALERT` |

**`PASS ⟺ OK`** (0–2, auto-trust); **`FLAG`** covers everything ≥3 and grades into
`RISK` / `HIGH-RISK` / `ALERT`. A CI gate reads `GATE`; a human reads `LEVEL`; the reviewer reads
the `SCORE` + evidence. Nothing is lost — the projections are pure convenience over the same band.

Live catalog + audit reports: **https://skills.j-amani.de**

## Read-only by design

No auditor ever executes the target, runs `npm install`, fires CI, or fetches a download
URL. Clone into a throwaway dir, read, score.

## Why

Part of [mnemo](https://github.com/amaniagent/mnemo) — an open memory framework for AI agents.
Skills are executable trust: you install someone's instructions *and their scripts* into an
agent that can touch your files, your keys, your machine. A supply chain needs a gate.

MIT. PRs welcome — especially new evidence patterns and new categories.
