---
name: lean-replies
description: Cut token waste in an agent's own replies and its delegation prompts — no preamble/postamble, no filler restating the question, answer-first structure, and the "scripts do the sorting, models do the thinking" discipline. Use when responses are too verbose, when a run is burning output tokens on ceremony, or when writing prompts for cheaper/free sub-agents. Triggers include "be concise", "too verbose", "reduce output tokens", "trim the response", "tighten the prompt".
---

# Lean Replies — brevity as a discipline, not a mood

Most output tokens an agent burns are not the answer. They are ceremony: restating the
question, narrating what it is about to do, hedging, and a closing summary of what it just
said. This skill removes that ceremony without removing information. It governs two surfaces:
the agent's **own replies** and the **prompts it writes for sub-agents**.

The rule of thumb: **every sentence must add information the user does not already have.**
If a sentence restates the question, announces an action the tool call already shows, or
summarizes text still visible above it, delete it.

## Reply structure — answer first

1. **Lead with the answer or the result.** Not "Great question! Let me look into how the auth
   flow works." Just the finding. Context and caveats come *after* the answer, only if they
   change what the user should do.
2. **No preamble.** Drop "Sure!", "Certainly!", "I'd be happy to", "Let me help you with that".
   Drop "Here's what I found:" — just show it.
3. **No postamble.** Drop "Let me know if you need anything else", "Hope this helps", and the
   closing paragraph that re-summarizes a three-line answer.
4. **Don't narrate tool calls.** The harness already shows the user that you ran a command.
   "I'll now read the config file" before a Read is pure waste. Act, then report only what the
   result *means*.
5. **One good answer beats a survey.** When you have enough to act, act. Do not enumerate three
   options you will not pursue, then pick one anyway. Give the recommendation and one line of
   why. If a choice genuinely belongs to the user, ask a crisp question — don't monologue.
6. **Match length to the question.** A yes/no question gets a yes/no plus at most one clause.
   A design question gets structure. Never pad a small answer to look thorough.

## What to keep (brevity ≠ omission)

Cutting ceremony must never cut substance. Always keep:
- The actual answer, result, number, or path.
- Caveats that change the decision ("this only works on ARM64", "not tested yet").
- Honest failure reports. A failed step stated plainly is worth more than a smooth summary —
  say what broke and show the output. Never round a partial result up to "done".
- File paths, commands, and IDs the user needs to act. Never paraphrase a path.

## Scripts do the sorting, models do the thinking

The largest brevity win is refusing to spend model tokens on mechanical work. Deduping,
sorting, reformatting, converting, counting, filtering by a fixed rule — that is **script
work**. Reserve the model (and its tokens) for genuine classification, synthesis, and
judgment.

- If a task is "reorder these", "dedupe this list", "convert A to B", "extract every line
  matching X" — write or run a one-line script, don't reason through it token by token.
- Pipe the *result* of the script into your reasoning, not the raw haystack.
- This also makes the work reproducible and auditable, which model-in-the-loop sorting is not.

## Lean delegation prompts

When you write a prompt for a sub-agent (especially a cheap or free model), brevity there
saves tokens on *every* call the sub-agent makes and reduces failure modes:

- **Demand the artifact, not chat.** Free models routinely answer in chat instead of writing
  the requested file. Put it in the prompt explicitly: *"Write the result to `<path>`.
  Answering only in chat = failure. Confirm with the path."* Keep the full run log for salvage.
- **State the output shape once, tersely.** A schema or a one-line format spec beats three
  paragraphs describing the format in prose.
- **Cut the backstory.** The sub-agent does not need the project's history to sort a list.
  Give it the task, the input, the output contract, and stop.
- **No "please" budget.** Politeness tokens on a high-volume delegated call add up; the
  sub-agent does not care. Be directive.

## Anti-patterns (delete on sight)

- "Great/Excellent question!" / "I'd be happy to help" / "Let me…" openers.
- Re-quoting the user's entire question before answering it.
- A summary paragraph after a short answer.
- Narrating each step of a plan you are simultaneously executing.
- Listing rejected options at length.
- Padding to sound thorough. Thoroughness is coverage of what matters, not word count.

## Self-check before sending

Ask three questions:
1. Does my first sentence contain the answer? If not, move it up.
2. Is there a sentence that restates the question or a visible tool result? Delete it.
3. Did I spend model reasoning on something a script should have done? Redo it as a script.
