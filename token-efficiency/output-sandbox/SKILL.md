---
name: output-sandbox
description: Stop dumping verbose tool and command output into the context window. Redirect it to a file, extract only the signal with standard tools, and keep the full output retrievable behind a handle — the same 80–98% context saving as an output-sandboxing plugin, but as a zero-dependency discipline that works in any agent. Use when a command, test run, build, log, or API call produces far more output than you need, or when a long session keeps drowning in tool results. Triggers include "tool output is huge", "the log is enormous", "context filling with command output", "sandbox this output", "reduce output tokens".
---

# Output Sandbox — capture to disk, return the signal, keep the rest retrievable

The single biggest context leak in an agent session is **raw tool output pasted straight into the
window**: a 300 KB test log, a build dump, a `kubectl get -o yaml`, a giant JSON response. The
answer you needed was three lines. This skill is the discipline that keeps the firehose out of the
context while losing nothing: **run it into a file, extract the signal, keep the handle.**

The rule: **no verbose tool output enters the context verbatim.** It goes to disk; only the
extracted signal comes back; the full output stays one command away if you need it.

## The core loop

1. **Sandbox the output to a file** instead of letting it print into context:
   ```bash
   <command> > /tmp/run.log 2>&1; echo "exit=$?"          # capture stdout+stderr, keep exit code
   <command> 2>&1 | tee /tmp/run.log | tail -5             # see a little, store all
   ```
2. **Extract only the signal** with standard tools — never `cat` the whole file:
   ```bash
   grep -nE "error|fail|warn" /tmp/run.log | head -20      # the parts that matter
   tail -30 /tmp/run.log                                    # where failures usually land
   wc -l /tmp/run.log                                       # how big before you decide to read
   jq '.items[].metadata.name' /tmp/resp.json              # pull fields, don't read raw JSON
   awk '/PASS|FAIL/{print}' /tmp/test.log | tail            # structured slice
   ```
3. **Report the signal + the handle.** Put the outcome in your reply — the exit code, the failing
   line, the count, the path — not the dump: *"Build failed (exit 1); first error at `run.log:214`:
   `undefined symbol foo`. Full log: `/tmp/run.log`."* The full output is retrievable; the context
   isn't polluted.

## What "extract the signal" means by output type

| Output | Pull this, drop the rest |
|---|---|
| Test run | pass/fail counts + the failing tests + their assertions (`grep FAIL`, `tail`) |
| Build | first error + its file:line; ignore the successful steps |
| Log file | the error/warn lines and their timestamps; the last N lines |
| Big JSON | the specific fields (`jq`), never the whole document |
| `find` / listing | a count (`wc -l`) and a sample (`head`), not thousands of paths |
| API response | status + the field you asked about; store the body, quote the value |

## Persist across compaction — make the sandbox searchable

For long sessions, spent outputs still hold answers you'll want later. Don't re-run — **index the
captured logs into a small searchable store** and query it after a compaction:

- Keep captures in one directory (`~/.cache/agent-runs/` or a scratch dir), one file per run with a
  descriptive name.
- For a long-lived session, treat that directory as a wiki and index it (BM25 is enough — see
  `composable-wiki-rag`). After a compaction, **query the store** ("what was the error in the
  migration run?") and get the original lines back instead of re-running the command.
- This is the same move as a session-RAG (`layered-agent-memory`): the primary source stays on
  disk, and you retrieve it on demand rather than carrying it in context.

## On indexed source, don't produce the output at all

The cheapest output to sandbox is the one you never generate. On a repo covered by a code graph,
reach for graph queries over raw dumps (see `use-gortex`): a symbol's source over a whole-file
`cat`, `compress_bodies` to elide bodies you don't need, a compact wire format (`gcx`) over verbose
JSON. Prefer a targeted query to capturing-then-filtering a huge listing.

## Scripts sort, the model reads the summary

Extracting the signal is **script work** — `grep`/`jq`/`awk`/`wc`, not model tokens spent reading a
log line by line. Pipe the *result* of the extraction into your reasoning, never the haystack. (Same
discipline as `lean-replies`: mechanics belong in scripts.)

## Optional: enforce it automatically

The discipline above is portable and needs nothing installed. If you want it enforced without
relying on discipline, wire a **`PreToolUse` hook** that redirects any Bash command whose output
would exceed a threshold into a log file and returns a truncated head/tail + the path — the same
outcome an output-sandboxing plugin achieves, using only your own hook and standard tools (no
extra dependency, no server). Keep the threshold generous so small outputs pass through untouched.

## Self-check

1. Am I about to let a command print more than ~50 lines into context? Redirect it to a file first.
2. Did I `cat` a whole file when a `grep`/`tail`/`jq` would answer the question? Redo it.
3. Is the full output still retrievable (path kept) if I need more later?
4. In a long session — are my captures in one indexable place so I can query, not re-run?
