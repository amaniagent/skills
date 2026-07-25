---
name: "cli-anything-obsidian"
description: >-
  Command-line interface for Obsidian — Knowledge management and note-taking via Obsidian Local REST API. Designed for AI agents and power users who need to manage notes, search the vault, and execute commands without the GUI.
---

# cli-anything-obsidian

Vault access via the Obsidian **Local REST API** — for what a plain file read/write on the vault
folder can't do: live queries, the active note, and the command palette.

Requires Python 3.10+ and Obsidian running with the
[Local REST API plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) enabled.

<!-- security: do NOT pip install — package name unregistered on PyPI (dependency-confusion risk), see ATTRIBUTION.md -->
```bash
cli-hub install obsidian
export OBSIDIAN_API_KEY=YOUR_KEY     # or --api-key
                                     # host defaults to https://localhost:27124, override with --host
cli-anything-obsidian server status  # verify the API is up before anything else
```

## The parts that aren't just file I/O

```bash
# Dataview DQL query — default --type dql, sent as
# application/vnd.olrapi.dataview.dql+txt
cli-anything-obsidian search query 'TABLE file.link FROM "Projects"'

# JsonLogic query — application/vnd.olrapi.jsonlogic+json
cli-anything-obsidian search query --type jsonlogic \
  '{"==":[{"var":"frontmatter.status"},"active"]}'

# Command palette: list IDs, then run one
cli-anything-obsidian command list
cli-anything-obsidian command execute "editor:toggle-bold"

# The note the human is looking at right now
cli-anything-obsidian note active
```

The **content type is the whole trick** with `search query`: DQL and JsonLogic go to two different
content types behind one `--type` flag, so the flag has to match the query language you wrote.

## The rest

`vault list|read|create|update|delete|append`, `search simple <text>` (plain text,
`GET /search/simple/`), `note open`, `session status`. For these a direct Read/Write/Grep on the
vault folder usually does the job without the API.

Driving it from an agent: always `--json`, check the return code (0 = success), read stderr for the
error message on failure. No subcommand enters an interactive REPL.

## Version

1.1.0
