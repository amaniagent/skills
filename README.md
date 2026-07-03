# amaniagent / skills

Security-auditing skills for AI coding agents (Claude Code, Cursor, Codex, …).
Both score on the **same 0–8 danger scale** — evidence-anchored, fair, non-alarmist:
they score *capability*, and name the likely *intent* separately.

| Skill | Audits | Install |
|-------|--------|---------|
| [**skill-auditor**](skill-auditor/) | a single agent skill / plugin / MCP before you trust it | `npx skilladd amaniagent/skills/skill-auditor` |
| [**repo-auditor**](repo-auditor/) | a whole GitHub repo / package before you clone or install | `npx skilladd amaniagent/skills/repo-auditor` |

## The 0–8 scale

`0` safe · `1` benign · `2` low · `3` notable · `4` elevated · `5` risky · `6` dangerous ·
`7` hostile · `8` extremely malicious. **Score = highest band with confirmed file:line evidence.**

The point: a skill or repo can look *green* (popular, reputable author) yet carry a wide,
undisclosed capability surface — a design skill that phones home and spawns permission-
bypassed sub-agents, or a browser tool whose `postinstall` downloads a binary with no
checksum. These auditors make that surface visible **without** falsely branding the author
malicious. A `4/8` means "adopt with mitigation X," not "forbidden."

## Why

Built as part of [mnemo](https://github.com/amaniagent/mnemo) — an open memory framework
for AI agents. Skills are executable trust: you install someone's instructions *and scripts*
into an agent that can touch your files, your keys, your machine. A supply chain needs a gate.
These are that gate. Live catalog + scores: **https://skills.j-amani.de**

## Read-only by design

Neither auditor ever executes the target, runs `npm install`, fires CI, or fetches a
download URL. Clone into a throwaway dir, read, score. That's it.

## License

MIT. Use them, fork them, harden them. PRs welcome — especially new evidence patterns.
