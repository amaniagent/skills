---
name: use-cli-anything
description: Before hand-rolling curl/API calls or docker invocations to drive a tool, check whether cli-hub (CLI-Anything) already offers an agent-native CLI for it — a deterministic, self-documenting wrapper with its own SKILL.md. Covers capability search, discovery, install/launch, curated multi-CLI workflow matrices, and the audit gate before trusting a third-party harness. Use when an agent needs to operate an external tool/service and you're about to write raw HTTP or shell glue. Triggers include "use cli-anything", "cli-hub", "is there a CLI for this", "drive this tool from an agent", "find a CLI for this task".
---

# Use CLI-Anything — reach for an agent-native CLI before hand-rolling glue

`cli-hub` (CLI-Anything) is a manager for ~96 **agent-native CLIs** ("harnesses") plus public
CLIs, grouped by category, with a capability search and curated multi-CLI workflow matrices. Each
harness is a deterministic wrapper (stable flags, structured output) that ships **its own
`SKILL.md`** — so it self-documents for the agent driving it.

**The reflex:** when you're about to write raw `curl`/API calls or `docker` glue to operate a
tool, first check if cli-hub already has an agent-native CLI for it. An agent-native CLI beats
hand-rolled HTTP every time — fewer tokens, deterministic flags, structured output, reproducible,
and it carries a SKILL.md telling you exactly how to use it.

## Discover

```bash
cli-hub can "transcribe audio"        # capability search across the workflow matrices
cli-hub search <name-or-keyword>       # search CLIs by name / description / category
cli-hub list                           # all available CLIs, grouped by category (~96)
cli-hub info <name>                    # details before you commit — see below
```

`cli-hub info <name>` is the decision point. It shows:
- **Requires** — what must already be running (e.g. "Ollama running at http://localhost:11434").
- **Source** — `harness` (built by the CLI-Anything team) vs `public` / `npm` / `script`
  (third-party). This drives the trust decision below.
- **Entry point** and **Skill** — the command it installs and the path to its bundled
  `skills/cli-anything-<name>/SKILL.md`.
- **Status** — installed or not.

## Use

```bash
cli-hub install <name>                 # install one CLI
cli-hub launch <name> [args...]        # run it, passing through arguments
cli-hub update <name>                  # update to latest
cli-hub uninstall <name>
```

After installing, read the bundled `skills/cli-anything-<name>/SKILL.md` — the harness is designed
to be agent-driven and that SKILL.md is the authoritative usage guide.

## Multi-CLI workflows: matrices

For bigger tasks that span several tools, a **matrix** is a curated bundle (e.g. `video-creation`,
`knowledge-research`, `image-design`, `game-development`, `3d-cad`):

```bash
cli-hub matrix list                    # available matrices + install progress
cli-hub matrix search <query>          # by capability / provider / recipe
cli-hub matrix recipes                 # task-oriented recipes across matrices
cli-hub matrix info <name>             # what's in it
cli-hub matrix preflight <name>        # which providers are available in this environment
cli-hub matrix doctor <name>           # audit install completeness, get fix suggestions
cli-hub matrix install <name>          # install the matrix's CLIs (optionally scoped)
```

Run `preflight`/`doctor` before committing to a matrix — they tell you what's missing and what's
already usable, so you don't install a 14-CLI bundle to use one tool.

## Trust gate — install and launch run code

`install` and `launch` **download and execute code**, so treat them as actions with side effects,
not read-only lookups:

- Inspect `cli-hub info <name>` first: prefer `harness` source; for `public`/`npm`/`script`
  third-party CLIs, read the bundled SKILL.md and, when in doubt, run the harness + its repo
  through a skill-auditor / repo-auditor pass **before** trusting it. Don't install an unknown CLI
  blindly to satisfy a task.
- Check **Requires** — many harnesses expect a local service already running; installing the CLI
  won't start that service.
- Read-only exploration (`can`, `search`, `list`, `info`, `matrix list/info/search/recipes`) is
  always safe; save `install`/`launch` for CLIs you've vetted.

## When there's no harness yet

If `cli-hub search <tool>` returns nothing, no agent-native CLI exists yet for that tool — fall
back to its API/CLI directly (see the tool's own `use-<tool>` skill). The CLI-Anything harness is
also the *preferred shape* for wrapping a self-hosted service for agents: a small deterministic CLI
(entry point + `client.py` + a `SKILL.md`) that any agent can drive, rather than every agent
re-deriving the raw HTTP calls.
