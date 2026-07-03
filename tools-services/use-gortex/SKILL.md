---
name: use-gortex
description: Work on an indexed codebase through Gortex's code-graph tools instead of raw file reads and text search. Maps every "I'd normally grep/read/edit" reflex to the graph query that answers it with far fewer tokens and zero false positives. Use whenever operating on a repo tracked by the Gortex daemon — searching for symbols, tracing callers, reading a function, assessing blast radius, or editing indexed source. Triggers include "use gortex", "search the graph", "who calls this", "what breaks if I change this", "trace this call path".
---

# Use Gortex — query the graph, don't scan the files

Gortex indexes a repo into a code graph (symbols, references, call edges, contracts, dataflow).
On an indexed repo, a graph query beats `grep`/`read` on two axes: **far fewer tokens** (it
returns the symbol, not the file) and **zero false positives** (it resolves references, not text
matches). This skill is the reflex-to-tool map plus the safe-edit workflow.

**Precondition:** the daemon is running and the repo is tracked. Check with `gortex daemon
status`; if the cwd isn't covered, `gortex track <path>`. If the daemon is down, start it
(`gortex daemon start --detach`) and retry. When Gortex is unavailable, fall back to normal
reads/search — but prefer the graph whenever it's up.

## Search & navigation — replace grep/glob

| Reflex | Use instead |
|---|---|
| grep for a symbol by name | `search_symbols` (BM25 + camelCase-aware) |
| grep for all references | `find_usages` (resolved, no false positives) |
| grep to find callers | `get_callers` / `get_call_chain` |
| grep for TODO/FIXME/HACK | `analyze kind=todos` (filter by tag/assignee/ticket) |
| grep for routes/handlers | `contracts` (list to enumerate, check to match cross-repo) |
| glob over source (`**/*.go`) | `get_repo_outline` / `search_symbols` |
| several reads to orient on a task | `smart_context` (one call) |

## Reading source — replace whole-file reads

| Reflex | Use instead |
|---|---|
| read a whole file for one function | `get_symbol_source` (add body-elision for just the signature) |
| read a file to understand it | `get_file_summary` / `get_editing_context` |
| read to check a signature | `get_symbol` (signature in the metadata) |
| read to trace calls | `get_call_chain` / `get_callers` |
| read a non-indexed / raw file | `read_file` (honours editor-buffer overlays) |

Add a **body-elision** flag (`compress_bodies`) when you only need the surface — signatures,
doc-comments, imports stay; bodies collapse to a stub. Compose with a compact wire format
(`format: "gcx"`) for stacked token savings on list-shaped responses.

## Editing & refactoring — atomic, auto-reindexed

| Reflex | Use instead |
|---|---|
| edit a file by string match | `edit_file` (no pre-read required, atomic, auto-reindex; `dry_run` to preview) |
| write a new file / full rewrite | `write_file` (creates parent dirs; `dry_run` to preview) |
| read→edit roundtrip for one symbol | `edit_symbol` (edit by ID) |
| manual find-and-replace rename | `rename_symbol` (updates cross-file refs) |
| sequencing multi-file edits by hand | `batch_edit` (dependency-ordered) |

## Impact before you edit — measure the blast radius

Before changing a signature, deleting a symbol, or touching a contract, ask the graph what
depends on it rather than guessing:

- `get_dependents` / `find_usages` / `get_callers` — who breaks if this changes.
- `find_implementations` — every implementor of an interface/contract.
- `get_test_targets` — which tests to run for a change.
- Impact/verify tools (`verify_change`, `explain_change_impact`) — broken callers and contract
  violations from a proposed edit, in one pass.

A safe-edit loop: preview the edit → check blast radius → apply → run the named test targets.

## Dataflow & reachability

- `flow_between(source, sink)` — ranked dataflow paths between two symbols.
- `taint_paths(source_pattern, sink_pattern)` — pattern-driven source→sink sweep.
- `trace_path(from, to)` — shortest call path; on no-path, a diagnosis of where the chain breaks.

## Structural & quality queries

- `search_ast` — find every code site matching an AST shape or a bundled anti-pattern detector
  (error-not-wrapped, sql-string-concat, weak-crypto, …). The missing primitive between
  name-search and reference-search.
- `find_clones` — near-duplicate function clusters (`dead_only: true` for safe-to-delete dupes).
- `analyze kind=<...>` — one dispatcher for dead_code, hotspots, cycles, coverage_gaps,
  ownership, routes, models, and more.

## Token economy (always on)

- Pass `format: "gcx"` on list-shaped calls — round-trippable, ~27% fewer tokens.
- Pass `compress_bodies: true` on source reads when you need the shape, not the logic. It's a
  no-op when the language has no grammar binding, so it's safe to set unconditionally.
- Use sparse `fields` and pagination (`cursor`) instead of a giant `limit`.

## Session memory (why, not just what)

Gortex remembers code; its note/memory layer remembers *decisions*.

- On starting work in a repo you've touched before: `distill_session` to reload prior decisions
  and pinned notes before reading anything.
- After a real decision, a rejected alternative, or a discovered invariant: save it (a session
  note for scratch, a durable memory for team-wide knowledge), mentioning symbol IDs so it
  auto-links.
- Before editing a symbol you've touched before: query notes/memories on that symbol ID —
  prior warnings ride along with it.

## The one rule

On an indexed repo, **reach for the graph query first.** Files are the fallback, not the
default. Every `read`/`grep` you replace with a symbol query is tokens saved and false positives
avoided.
