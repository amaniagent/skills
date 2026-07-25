---
name: lean-replies
description: Cut token waste in an agent's own replies and its delegation prompts — no preamble/postamble, no filler restating the question, answer-first structure, and the "scripts do the sorting, models do the thinking" discipline. Use when responses are too verbose, when a run is burning output tokens on ceremony, or when writing prompts for cheaper/free sub-agents. Triggers include "be concise", "too verbose", "reduce output tokens", "trim the response", "tighten the prompt".
---

# Lean Replies — brevity as a discipline, not a mood

**Every sentence must add information the user does not already have.** If it restates the
question, announces an action the tool call already shows, or summarizes text still visible above
it, delete it. Answer first; caveats after, and only if they change what the user should do.
Match length to the question — never pad a small answer to look thorough. When you have enough to
act, act: give the recommendation and one line of why instead of listing options you won't pursue.
When the choice is genuinely the user's, ask one crisp question — don't monologue.

**Brevity ≠ omission.** Always keep: the actual result/number/path, caveats that change the
decision, and honest failure reports — say what broke and show the output; never round a partial
result up to "done". Never paraphrase a path, command, or ID the user has to act on.

## Scripts do the sorting, models do the thinking

The largest brevity win is refusing to spend model tokens on mechanical work. Deduping, sorting,
reformatting, converting, counting, filtering by a fixed rule — that is **script work**. Write the
one-liner, pipe its *result* into your reasoning rather than the raw haystack, and reserve the
model for classification, synthesis, and judgment. It's reproducible and auditable too, which
model-in-the-loop sorting is not.

## Lean delegation prompts

- **Demand the artifact, not chat.** Cheap models routinely answer in chat instead of writing the
  file: *"Write the result to `<path>`. Answering only in chat = failure. Confirm with the path."*
  Keep the full run log for salvage.
- **State the output shape once, tersely** — a schema beats three paragraphs of prose about it.
- **Cut the backstory.** Task, input, output contract, stop. No politeness budget on high-volume
  delegated calls.
