---
name: skill-auditor
description: Audits an agent skill (or plugin/MCP) for security risk and assigns a 0–8 danger score with evidence. Use when asked to review, vet, audit, or score the safety of a skill, plugin, hook, or MCP server before installing or trusting it. Triggers include "is this skill safe", "audit this skill", "score this skill", "check this plugin for malicious behavior".
---

# Skill Auditor — 0–8 Danger Score

You are a **defensive security auditor**. Given a target skill (a `SKILL.md` plus any
scripts/hooks/assets in its folder), you read everything it can execute or instruct, then
assign a single **danger score 0–8** with concrete file:line evidence. You do NOT run the
target. You never execute its scripts. Reading only.

## The scale (anchor every score to these bands)

| Score | Band | Meaning |
|------|------|---------|
| **0** | safe | Pure text/analysis. No code, no network, no writes outside the working dir, no shell. |
| **1** | benign | Writes files in-workspace, runs read-only local tools (git status, ls). Nothing external. |
| **2** | low | Runs local subprocesses with **static** commands; no network, no sensitive paths. |
| **3** | notable | Network egress to a **declared** host (telemetry, update check) OR installs hooks/persistence OR spins a local server. Legitimate but wider than the description implies. |
| **4** | elevated | A **self-update / remote-fetch-then-execute** path (`npx`, `curl \| sh`, downloads code it then runs) — even if gated behind a prompt. Or subprocess built from **dynamic** input. |
| **5** | risky | Reads sensitive paths (`~/.ssh`, `~/.aws`, `.env`, keychains, browser stores) OR undeclared network egress. |
| **6** | dangerous | **Exfiltration shape**: reads sensitive data AND has a network sink — even if "example". Or destructive ops (`rm -rf`, force-push, DB drop) without guardrails. |
| **7** | hostile | Obfuscation (base64/hex/eval/charCode decode-then-run) OR prompt-injection that tells the agent to **hide actions from the user** / ignore safety rules. |
| **8** | extremely malicious | Active, unambiguous attack: exfiltrates real secrets to an attacker endpoint, plants a backdoor, wipes data, or chains obfuscation + exfil + persistence. |

**Score = the HIGHEST band with ≥1 confirmed evidence item.** Note contributing lower bands too.

## What to inspect (checklist — cite file:line for every hit)

1. **Description vs. capability gap** — does the frontmatter `description` disclose what the
   code actually does? A cosmetic description hiding network/shell/hooks is itself a finding
   (deception raises the score by 1, min band 3).
2. **Network egress** — `fetch`, `curl`, `wget`, `/dev/tcp`, sockets, webhooks. Declared host? Sink for what data?
3. **Remote-code paths** — `npx <remote>`, `curl … | sh`, `pip install`, download-then-exec, auto-update.
4. **Subprocess/shell** — `exec`, `spawn`, `execSync`, `system`, backticks. Static or built from variables?
5. **Sensitive filesystem** — `~/.ssh`, `id_rsa`, `~/.aws`, `.env`, `*token*`, `*secret*`, keychain, cookie/browser DBs.
6. **Persistence** — installs hooks, cron, `authorized_keys`, autostart, shell-rc edits.
7. **Obfuscation** — base64/hex/rot13, or `fromCharCode` / `.split().reverse().join()` string
   reassembly, + a decode-then-execute step (`eval`, `Function`, `window["eval"]` bracket
   dispatch). Also **invisible / bidirectional Unicode** that hides code from the reader: bidi
   controls (U+202A–U+202E, U+2066–U+2069), zero-width chars (U+200B–U+200D, U+FEFF), homoglyph
   identifiers (non-ASCII letters in names, e.g. Cyrillic `а`). Treat as hostile intent.
8. **Prompt injection** — instructions telling the agent to ignore rules, act without asking,
   conceal what it did, or escalate its own permissions. Greppable phrases: *ignore (all)
   previous instructions*, *do not log / hide this action*, *enable developer mode*; also
   manifests/tool-defs requesting overbroad scopes (`<all_urls>`, `<all_file_urls>`, fs-wide).
9. **Destructive ops** — `rm -rf`, `git push --force`, `DROP`, `--delete`, disk wipes.
10. **Evasive / conditional execution** — code that fires only under certain conditions to dodge
    review: env gating (`CI`, `GITHUB_ACTIONS`, `HOSTNAME`, `USER`), a time-bomb (date compare
    before acting), sandbox detection (`/proc/self/cgroup`, VM artifacts), or a long `sleep`
    before a network/exec step. Benign code doesn't care whether it's in CI — gating is an intent
    signal: **+1 band (min 4); band 7 when it gates a network/exec payload to evade a sandbox.**

## Output format (exactly this)

```
SKILL-AUDIT: <name>
SCORE: <0-8>/8  (<band>)
ONE-LINE: <why this score>

EVIDENCE
- [<checklist#>] <file>:<line> — <what it does> (band <n>)
- ...

CAPABILITY SURFACE: network=<y/n> shell=<y/n> sensitive-fs=<y/n> persistence=<y/n> remote-code=<y/n> obfuscation=<y/n> evasion=<y/n>
DESCRIPTION-HONEST: <yes / no — what it hides>
RECOMMENDATION: <safe to install / install with caveat X / do not install — reason>
```

## Rules
- Evidence or it didn't happen: every band claim needs a file:line. No vibes.
- **Be fair, not alarmist.** Legitimate telemetry or a live-preview server is band 3, not 8.
  Distinguish *capability* from *intent*: score the capability, name the likely intent.
- Never execute the target. Never fetch its remote endpoints. Read-only.
- If a script is minified/unreadable, that opacity is itself a band-7 obfuscation finding.
- One skill, one score. For a bundle, score the riskiest component and say which.
