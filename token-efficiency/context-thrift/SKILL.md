---
name: context-thrift
description: Spend fewer tokens on the context an agent loads — tool outputs, retrieved documents, file reads, and conversation history — without losing signal. Covers compact wire formats, body-elision on source reads, observation masking, compaction thresholds, and retrieval scoping. Use when a session is running out of context, tool outputs dominate the window, or reads are pulling far more than needed. Triggers include "running out of context", "tool output is huge", "compress the context", "reduce tokens on reads", "context is bloated".
---

# Context Thrift — pay for signal, not for shape or bulk

Tool outputs and file reads typically consume the majority of an agent's context — often 80%+.
The answer text is small; the machinery around it is large. This skill cuts that bulk along two
independent axes you should **compose**: the *shape* of a response (its encoding) and its
*content* (how much source it carries). Measure before optimizing, and keep everything
retrievable — thrift is not amnesia.

## Axis 1 — shape: use compact wire formats

Structured, list-shaped tool responses (search hits, symbol lists, references, analysis rows)
carry heavy JSON scaffolding. When a tool supports alternative encodings, prefer the compact one.

- **Order of preference: `gcx` > `toon` > `json`.** GCX1 is round-trippable and ~27% smaller;
  TOON is tabular and compact but lossy; JSON is the verbose fallback.
- Pass the format explicitly on list-shaped calls (search, usages, callers, analysis, outlines).
  Many tools default to a compact format for known clients, but an explicit arg removes doubt.
- Use **sparse fieldsets** when a tool supports them: request only the columns you need
  (e.g. `fields: "id,line"`) instead of every attribute per row.
- **Paginate instead of one giant limit.** A cursor-based page keeps each response inside the
  budget; a huge `limit` blows it and forces a lossy truncation you don't control.

## Axis 2 — content: elide bodies you don't need

When reading source to learn its *surface* (signatures, structure, imports) rather than its
logic, elide the bodies:

- Prefer **symbol-level or summary reads** over whole-file reads: get one function's source, a
  file summary, or an editing context instead of dumping 2000 lines to check one signature.
- Use **body-elision** when the tool offers it (`compress_bodies`-style flags): it replaces
  function bodies with a `{ /* N lines elided */ }` stub while keeping signatures, doc-comments,
  imports, and top-level declarations. A 200-line file lands at ~30–40% of its tokens.
- The two axes **stack**: a compact wire format shrinks the response shape; body-elision shrinks
  its content. Apply both when you only need the map, not the territory.

## Observation masking — reclaim tokens from spent outputs

Once a tool output has served its purpose, its verbose form is dead weight. Mask selectively by
recency and ongoing relevance — never uniformly.

- **Never mask:** the current task's critical observations, the most recent turn, outputs used
  in an active reasoning chain, and error output while a bug is still being chased.
- **Mask after it's been consumed:** verbose outputs whose key points you already extracted.
  Replace with a compact reference — key finding plus a pointer — and keep the full content
  retrievable (on disk, or re-fetchable) so you can pull it back if needed.
- **Mask immediately:** duplicated outputs, boilerplate headers/footers, anything already
  summarized earlier.

Target 60–80% reduction on masked observations at <2% quality impact. The discipline is
*retrievability*: elide the bulk, keep the handle.

## Compaction — summarize before the window forces it

When context utilization crosses ~70%, summarize and reinitialize rather than waiting for a
pressured, low-quality auto-compaction at 90%+.

- Compress in priority order: **tool outputs first** (biggest and most disposable), then old
  conversation turns, then retrieved documents. **Never compress the system prompt or task
  goal** — those anchor behavior.
- Preserve by type: from tool outputs keep findings/metrics/error-codes; from turns keep
  decisions, commitments, and constraints; from documents keep the task-relevant facts.
- Target 50–70% reduction at <5% quality loss. If you exceed 70% reduction, re-read the summary
  for dropped constraints — over-compaction is the common failure. After compacting, re-validate
  the summary against the *current* goal; a stale summary looks authoritative but misleads.

## Retrieval scoping — don't load what you won't use

The cheapest token is the one you never retrieve.

- Scope queries tightly: filter by path/kind/repo before pulling rows. A narrow query beats a
  broad one plus post-hoc filtering in-context.
- Pull the smallest unit that answers the question: a signature over a body, a summary over a
  file, a file over a directory.
- For RAG, retrieve top-k with k as small as the task tolerates and rerank; don't stuff the
  window with marginal chunks that dilute attention (lost-in-the-middle) and cost tokens.

## KV-cache stability — keep the prefix immutable

If the runtime supports prefix caching, a stable prefix is free savings on every subsequent
call. A single changed byte upstream invalidates everything downstream of it.

- Keep the system prompt and tool definitions byte-stable within a session. Do not interpolate
  timestamps, session counters, or request IDs into them — that forces a cache miss per request.
- Put dynamic metadata in a later user message or tool result, after the stable prefix, not
  inside it.

## Decision framework

| What dominates the window | First action | Then |
|---|---|---|
| Tool outputs (>50%) | Observation masking | Compact remaining turns |
| Retrieved documents | Tighten retrieval scope + summarize | Drop marginal chunks |
| Whole-file reads | Symbol/summary reads + body-elision | Compact wire format |
| Message history | Compaction with selective preservation | — |
| Near-limit, debugging active | Mask only *resolved* outputs | Preserve all error detail |

## Self-check

1. Am I requesting the compact wire format on list-shaped calls?
2. Am I reading a whole file when a symbol or a body-elided read would do?
3. Is there a spent tool output I can mask to a reference and keep retrievable?
4. Did I retrieve anything I never actually used? Tighten the next query.
