---
name: use-cli-anything
description: Before hand-rolling curl/API calls or docker invocations to drive a tool, check whether cli-hub (CLI-Anything) already offers an agent-native CLI for it — a deterministic, self-documenting wrapper with its own SKILL.md. Covers capability search, discovery, install/launch, curated multi-CLI workflow matrices, and the audit gate before trusting a third-party harness. Use when an agent needs to operate an external tool/service and you're about to write raw HTTP or shell glue. Triggers include "use cli-anything", "cli-hub", "is there a CLI for this", "drive this tool from an agent", "find a CLI for this task".
---

# Use CLI-Anything — reach for an agent-native CLI before hand-rolling glue

`cli-hub` (CLI-Anything) manages ~96 **agent-native CLIs** ("harnesses") plus public CLIs. Each
harness is a deterministic wrapper (stable flags, structured output) shipping **its own
`SKILL.md`**, so it self-documents for the agent driving it.

**The reflex:** before writing raw `curl`/API calls or `docker` glue to operate a tool, check
whether cli-hub already has an agent-native CLI for it.

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

A **matrix** is a curated bundle for tasks spanning several tools (`video-creation`,
`knowledge-research`, `image-design`, `game-development`, `3d-cad`). Same verbs under
`cli-hub matrix …` (`list`, `search`, `recipes`, `info`, `install`) plus two worth knowing:
`preflight` (which providers exist in this environment) and `doctor` (install completeness + fix
suggestions). Run those before committing, so you don't install a 14-CLI bundle to use one tool.

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

If `cli-hub search <tool>` returns nothing, fall back to the tool's own API/CLI (see its
`use-<tool>` skill). The harness shape is still the target when *you* wrap a self-hosted service:
entry point + `client.py` + a `SKILL.md`, so agents drive a deterministic CLI instead of each
re-deriving the raw HTTP calls.
