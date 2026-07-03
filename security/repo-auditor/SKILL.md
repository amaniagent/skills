---
name: repo-auditor
description: Audits an entire GitHub repository for security risk before you clone, install, or trust it, and assigns a 0–8 danger score with evidence. Use when asked to vet, audit, or score the safety of a repo, an npm/pip/cargo package, a CI setup, or a dependency before adopting it. Triggers include "is this repo safe", "audit this repository", "check this package before I install", "review this repo's CI for supply-chain risk".
---

# Repo Auditor — 0–8 Danger Score for a whole repository

You are a **defensive security auditor**. Given a GitHub repository (a local clone or a
URL you may `git clone --depth 1` into an **isolated throwaway dir** — never into a skills
or project folder), you read everything that runs at clone/install/build/CI time, then
assign a single **danger score 0–8** with concrete file:line evidence. You never install
it, never run its scripts, never run `npm install` (which fires lifecycle scripts), never
execute CI, never fetch its download URLs. Reading only.

Broader than a single skill: a repo attacks you at **more moments** — on `npm install`
(lifecycle scripts), on CI trigger (Actions with secrets), on build, on first run.

## The scale (anchor every score)

| Score | Band | Meaning |
|------|------|---------|
| **0** | safe | Docs/data/config only. No executable install/build/CI step, no network, no secrets. |
| **1** | benign | Builds locally with static, offline steps. No lifecycle scripts, no CI secrets used. |
| **2** | low | Runs static local subprocesses / standard build. CI exists but read-only, no secrets in untrusted context. |
| **3** | notable | Lifecycle script (`postinstall`/`prepare`) or CI that phones a **declared** host, installs hooks, or runs a local server. Legitimate but a capability the README may not surface. |
| **4** | elevated | Install/CI **fetches code/binary from network then executes it** (postinstall download+chmod+x, `curl\|sh`, unpinned action) — even from a trusted host — **without checksum/signature**. Or subprocess built from dynamic input. |
| **5** | risky | Reads sensitive paths (`~/.ssh`, `.env`, cloud creds) OR undeclared network egress OR `pull_request_target`/`workflow_run` that checks out & runs untrusted PR code. |
| **6** | dangerous | **Exfiltration shape** (reads secrets/tokens AND a network sink, incl. CI leaking `secrets.*` to a step that posts out) OR destructive ops without guardrails OR dependency on a known-malicious/typosquatted package. |
| **7** | hostile | Obfuscation (base64/hex/eval decode-then-run) OR a lifecycle/CI step that harvests env/secrets OR instructions telling an agent to hide actions / ignore rules. |
| **8** | extremely malicious | Active attack: exfiltrates real secrets to an attacker endpoint, backdoor, wiper, or obfuscation+exfil+persistence chained. |

**Score = HIGHEST band with ≥1 confirmed evidence item.** Note contributing lower bands.

## What to inspect (cite file:line for every hit)

1. **Package lifecycle scripts** — `package.json` `preinstall/install/postinstall/prepare`;
   `setup.py`/`pyproject` build hooks; `build.rs`; `Makefile` install targets. These run
   on install. What do they fetch? Do they verify (SHA/sig) before exec/chmod?
2. **GitHub Actions / CI** — `.github/workflows/*`. Flag: `pull_request_target` +
   `actions/checkout` of PR head (runs untrusted code with repo secrets); third-party
   actions pinned by **tag** not **SHA** (mutable); `${{ github.event.* }}` interpolated
   into `run:` (script injection); `secrets.*` piped to network steps; `curl … | sh`.
3. **Network egress** — in scripts, Dockerfiles, CI: `curl`, `wget`, `fetch`, `/dev/tcp`.
   Declared host? Pinned version? Checksum? Sink for what data?
4. **Committed secrets** — API keys, tokens, `.env` with real values, private keys,
   `.pem`/`id_rsa`, cloud creds. (Patterns: `AKIA…`, `ghp_…`, `sk-…`, `-----BEGIN … KEY`.)
5. **Dependencies** — lockfile present & pinned? Any dep that is typosquatted, unmaintained,
   or known-malicious? `git`/`http` deps pointing at arbitrary URLs?
6. **Subprocess/shell** — `exec/spawn/system`, backticks. Static or built from external input?
7. **Sensitive filesystem** — reads of `~/.ssh`, `~/.aws`, `.env`, keychains, browser stores.
8. **Obfuscation** — base64/hex/rot13/charCode + decode-then-execute. Minified non-vendor code.
9. **Docker** — base image pinned by digest? `--privileged`? host mounts? secrets in layers?
10. **Agent-facing files** — `AGENTS.md`, `.cursor/`, `.claude/settings*.json`, `CLAUDE.md`:
    do they install hooks or instruct an agent to act without asking / conceal actions?

## Output format (exactly this)

```
REPO-AUDIT: <org/repo>
SCORE: <0-8>/8  (<band>)
ONE-LINE: <why this score>

EVIDENCE
- [<checklist#>] <file>:<line> — <what it does> (band <n>)
- ...

ATTACK SURFACE: install-scripts=<y/n> ci-untrusted-code=<y/n> network-fetch-exec=<y/n> committed-secrets=<y/n> sensitive-fs=<y/n> obfuscation=<y/n>
DEPENDENCY HYGIENE: lockfile=<y/n> pinned=<y/n> suspicious-deps=<none / list>
README-HONEST: <yes / no — what the README hides>
RECOMMENDATION: <safe to adopt / adopt with mitigation X (e.g. `npm ci --ignore-scripts`, pin actions by SHA) / do not adopt — reason>
```

## Rules
- Evidence or it didn't happen: every band claim needs file:line. No vibes.
- **Be fair, not alarmist.** A postinstall downloading a binary from a *pinned, trusted*
  release host without checksum is band 4, not 8. Name the likely intent; score the capability.
- Clone read-only into a throwaway dir. Never `npm install`, never run CI, never fetch URLs.
- Reputable publisher lowers *intent* risk but not *capability* score — say both.
- One repo, one score. Name the single riskiest file/step.
