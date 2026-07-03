---
name: layered-agent-memory
description: Give an agent a durable, inspectable memory built from layered markdown + YAML files instead of an opaque vector blob — with sensitivity enforced by storage location, composition by stable IDs, and a session-RAG for surviving context compaction. Distilled from the mnemo multi-layer memory framework. Use when designing how an agent remembers across sessions, when memory leaks the wrong data into the wrong place, or when a long conversation keeps losing earlier decisions. Triggers include "give the agent memory", "persist context across sessions", "design a memory system", "remember decisions", "memory keeps forgetting after compaction".
---

# Layered Agent Memory — markdown you can read, not a blob you can't

An agent's memory should be **inspectable, diffable, and access-controlled**. Store it as many
small markdown files with YAML frontmatter, organized into layers by kind and lifetime. You get
memory that a human can read and correct, that version control can track, and where trust is a
property of *where a file lives* — not a runtime filter that can be bypassed.

## Layer by kind and lifetime

Don't pool everything into one store. Separate by what the memory *is*, because each kind has a
different audience, retention, and sensitivity:

- **agent** — who the agent is: its building blocks, capabilities, operating rules.
- **project** — ongoing work, goals, and constraints not derivable from the code or history.
- **session** — transcript archives of past runs (raw material for the session-RAG below).
- **knowledge** — durable, reusable facts the agent has learned.
- **user** — who the user is: role, preferences, working style, corrections they've given.

Each file records **one fact or one unit**. Small files retrieve better and are safe to edit or
delete. Maintain one **index file** (a one-line pointer per memory) that loads into context each
session; the index is the map, the files are the territory. Update a file in place rather than
duplicating; **delete memories that turn out to be wrong** — a confidently stale memory is worse
than none.

## Every file carries YAML frontmatter

Markdown body for the human, frontmatter for the machine:

```markdown
---
title: <short name>
layer: project-memory
sensitivity: INTERNAL          # PUBLIC | INTERNAL | PRIVATE | SECRET
created: 2026-07-04            # absolute dates, never "yesterday"
owner: <who>
type: user | feedback | project | reference
---

The fact itself. Convert relative dates to absolute. Link related
memories with [[their-slug]] so the store becomes a graph you can walk.
```

Rules that keep the store trustworthy:
- **`sensitivity:` on every file.** No exceptions. It drives the enforcement below.
- **Absolute dates.** "Tomorrow" rots; `2026-07-04` doesn't.
- **Link liberally** (`[[slug]]`). A link to a memory that doesn't exist yet marks something
  worth writing later — it's a to-do, not an error.

## Sensitivity is enforced by storage, not by hope

The strongest access control is structural. Split the memory into **two repositories that mirror
the same folder shape**: a public *skeleton* (structure, code, PUBLIC files) and a private
*content* repo (the actual INTERNAL+ material). A file's sensitivity determines which repo it
lives in, so **INTERNAL-or-higher content can never end up in the public repo** — the boundary is
the filesystem, not a filter someone can forget to apply. Before any push to the public repo,
scan for secrets (a gitleaks pass) as a second gate.

## Compose by stable ID — never invent one

When memories reference reusable building blocks (skills, tools, personas, other memories),
compose them by their **registry ID**. Two hard rules:
- **Never fabricate an ID.** If a needed block doesn't exist, record `needs-blocks: [<name>]`
  and stop — do not invent a plausible-looking ID. Fabricated IDs are the #1 failure mode of
  free/cheap models building configs.
- **Gate composition with a validator.** A script that checks every referenced ID exists in the
  registry (exit 0 = pass) is the quality gate before anything ships.

## Write discipline for delegated memory

When a sub-agent is asked to persist something, its output must be a **file, not a chat message**.
Put it in the prompt explicitly: *"Write the result to `<path>`. Answering only in chat = failure.
Confirm with the path."* The caller keeps the full run log so a chat-only answer is still
salvageable. This one rule eliminates the most common "the agent said it saved it but didn't" bug.

## Session-RAG — survive context compaction

A long conversation loses its own early decisions when the window compacts. Fix it by making the
**transcript itself a retrievable wiki**:

1. Periodically split the running transcript into **blocks** (a user turn + the agent's response
   to it), each with light YAML metadata.
2. Index the blocks (BM25 is enough — see composable retrieval patterns) on a cron or on demand.
3. After a compaction, **query the session-RAG instead of guessing**: ask "why did we choose X?"
   and get back the *original* blocks — the real words, not a lossy summary.

**Anchored replies:** a session-RAG answer returns the source blocks, not a paraphrase, so the
agent re-reads what was actually decided. Memory that hands back the primary source can't
hallucinate the past.

## Why markdown beats an opaque vector store here

- **Inspectable:** a human can open, read, and correct any memory.
- **Diffable:** version control shows exactly what the agent learned and when.
- **Access-controlled by construction:** sensitivity + two-repo split makes leaks structurally
  hard, not policy-dependent.
- **Composable:** stable IDs + a validator make memory a set of building blocks, not a soup.
- **Portable:** it's just files. Any tool — grep, a BM25 index, a vector layer — can read them.
