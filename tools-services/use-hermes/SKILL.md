---
name: use-hermes
description: Delegate work to cheap or free LLMs headlessly via hermes (the Hermes Agent CLI) — one-shot runs, provider/model selection, and the hard-won disciplines that make free-model delegation actually work (demand a file artifact not chat, babysit the run, fail over across providers, forbid confabulated sources). Use when offloading bulk or parallel research/generation to free models while keeping a strong model as reviewer, or when a headless agent run stalls. Triggers include "delegate to a free model", "run hermes", "offload this to nvidia", "swarm this research", "free-LLM batch".
---

# Use Hermes — headless delegation to cheap/free models, done safely

`hermes` runs an agent headlessly from one command — ideal for offloading bulk research or
generation to **free/cheap models** while a strong model stays the reviewer. The value isn't the
command; it's the discipline around it. Free models fail in specific, repeatable ways, and this
skill is the guardrail set.

## The command

```bash
hermes --yolo -z "<prompt>" -m <model> [--provider <provider>]
```

- `-z "<prompt>"` — the one-shot task. `--yolo` runs non-interactively.
- `-m <model>` / `--provider <provider>` — pick the model and where it runs. The same model is
  often free on more than one provider; split load across them to spread rate limits.

## Provider & rate budgets (pick and fail over deliberately)

Free endpoints have hard caps — plan for them, don't discover them mid-swarm:
- **OpenRouter** — ~1000 requests/day, account-wide. A single agentic run can eat dozens, so this
  caps you at roughly 20–40 delegated runs/day. Throttles *before* the nominal cap.
- **NVIDIA** — ~32–40 requests/minute. The **default for swarms** (per-minute, not per-day).
- **Failover order: OpenRouter → NVIDIA.** When you hit `429 free-models-per-day`, switch provider,
  don't retry-loop the exhausted one.
- Some models stall on NVIDIA-direct — prefer routing those via OpenRouter, and mix providers.
- Never pay for a model that's available free elsewhere.

## The four disciplines that make free delegation work

1. **Demand a file artifact, not a chat reply.** Free models routinely "answer" in chat instead of
   writing the file you asked for. Put it in the prompt, verbatim: *"Write the result to `<path>`.
   Answering only in chat = failure. Confirm with the path."* Then verify the file exists.
2. **Keep the full run log.** Never rely on `tail -2` — salvageable output hides in the middle of a
   run that otherwise "failed". Capture stdout/stderr to a file per run.
3. **Babysit the swarm — never fire-and-forget.** Runs stall silently (429, timeout, file-not-
   written, chat-only). Poll at intervals (`pgrep` / check the output files), rotate models,
   re-launch dead runs. Ideal: a background poller loop, not blind waiting.
4. **Forbid confabulation explicitly.** Free models invent sources, DOIs, APIs, and IDs. Pin it in
   the prompt: *"You have NO internet access. Do not claim to have fetched anything or cite sources
   you didn't receive. If you don't know, say so."* Then have a strong model review the output for
   fabrication before trusting it.

## Parallel & background by default for batches

For bulk delegation, run **in the background and parallelized** — including the *same* model across
different free providers at once (e.g. OpenRouter + NVIDIA simultaneously) to spread the rate limit
and finish faster. This keeps your main session free to keep working. Respect each provider's cap;
report tallies on completion.

- Watch the `pkill -f <pattern>` self-kill trap: a kill pattern can match the launcher's own
  command line and take out your orchestrator (exit 144). Scope kill patterns tightly.

## The division of labour

**Scripts sort, models think; strong model reviews, free models produce.** Mechanical work
(dedupe, sort, convert, filter by a fixed rule) is script work — don't spend model tokens on it.
Reserve free models for genuine generation/classification, and keep a strong model (Opus/Claude) as
the teacher/reviewer that gates the output. Delegate as much of the *volume* as possible; never
ship free-model output unreviewed.

## Quick checklist before launching a swarm

1. Does every prompt demand a file + "chat-only = failure, confirm with path"?
2. Does every prompt forbid claimed internet access / invented sources?
3. Am I capturing the full log per run, and do I have a poller to catch stalls?
4. Is load split only across providers where the model is genuinely free?
5. Who's the reviewer, and what's the fabrication check before I trust the result?
