# amaniagent / skills

Security & tooling skills for AI coding agents (Claude Code, Cursor, Codex, …),
organized by category. Each skill is one folder with a `SKILL.md`.

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
*"audit these dependencies"* / *"audit this MCP server"* triggers the matching auditor.

## The 0–8 scale

`0` safe · `1` benign · `2` low · `3` notable · `4` elevated · `5` risky · `6` dangerous ·
`7` hostile · `8` extremely malicious. **Score = highest band with confirmed file:line evidence.**

A skill or repo can look *green* (popular, reputable author) yet carry a wide, undisclosed
capability surface. These auditors make it visible without falsely branding the author
malicious. A `4/8` means "adopt with mitigation X," not "forbidden."

`answer-verifier` scores the same 0–8 shape on a parallel **confabulation-severity** axis
(`0` grounded → `8` wholesale confabulation) and emits a `PASS / FLAG / FAIL` verdict — same
evidence discipline (every claim → a source, or `UNVERIFIABLE`), applied to *output* instead of
*code*.

Live catalog + audit reports: **https://skills.j-amani.de**

## Read-only by design

No auditor ever executes the target, runs `npm install`, fires CI, or fetches a download
URL. Clone into a throwaway dir, read, score.

## Why

Part of [mnemo](https://github.com/amaniagent/mnemo) — an open memory framework for AI agents.
Skills are executable trust: you install someone's instructions *and their scripts* into an
agent that can touch your files, your keys, your machine. A supply chain needs a gate.

MIT. PRs welcome — especially new evidence patterns and new categories.
