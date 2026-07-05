#!/usr/bin/env bash
# output-sandbox — Claude Code PostToolUse hook for the Bash tool.
#
# Caps oversized command output: writes the full output to ~/.cache/agent-runs/<ts>.log
# and returns only head+tail + the path via `updatedToolOutput`, so the firehose never
# lands in Claude's context while staying fully retrievable. Small output passes through.
#
# Wire it (settings.json):
#   { "hooks": { "PostToolUse": [ { "matcher": "Bash",
#       "hooks": [ { "type": "command",
#         "command": "$HOME/.claude/hooks/output-sandbox.sh", "timeout": 15 } ] } ] } }
#
# Fail-safe by design: any error / missing jq / non-Bash tool → exit 0 (output untouched).
# Never exits non-zero, so it can never block or break a Bash call.

set -uo pipefail

# Tunables (env-overridable)
THRESH_LINES="${OUTPUT_SANDBOX_MAX_LINES:-120}"
THRESH_CHARS="${OUTPUT_SANDBOX_MAX_CHARS:-12000}"
HEAD_N="${OUTPUT_SANDBOX_HEAD:-30}"
TAIL_N="${OUTPUT_SANDBOX_TAIL:-20}"
DIR="${OUTPUT_SANDBOX_DIR:-$HOME/.cache/agent-runs}"

INPUT=$(cat) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null) || exit 0
[ "$TOOL" = "Bash" ] || exit 0

# Extract the command output robustly (Bash response = object with stdout/stderr;
# fall back to string / .text / whole response).
FULL=$(printf '%s' "$INPUT" | jq -r '
  .tool_response as $r
  | if ($r|type)=="string" then $r
    elif ($r|type)=="object" then
      ((($r.stdout)//"") + (if (($r.stderr)//""|length)>0 then "\n--- stderr ---\n" + ($r.stderr//"") else "" end))
      | if (.|length)>0 then . else (($r.text)//($r|tostring)) end
    else ($r|tostring) end' 2>/dev/null) || exit 0

[ -n "$FULL" ] || exit 0

LINES=$(printf '%s\n' "$FULL" | wc -l | tr -d ' ')
CHARS=${#FULL}

# Under threshold → leave it alone.
if [ "${LINES:-0}" -le "$THRESH_LINES" ] && [ "${CHARS:-0}" -le "$THRESH_CHARS" ]; then
  exit 0
fi

mkdir -p "$DIR" 2>/dev/null || exit 0
LOG="${DIR}/$(date +%Y%m%d-%H%M%S)-$$.log"
printf '%s\n' "$FULL" > "$LOG" 2>/dev/null || exit 0

HEAD=$(printf '%s\n' "$FULL" | head -"$HEAD_N")
TAIL=$(printf '%s\n' "$FULL" | tail -"$TAIL_N")
ELIDED=$(( LINES - HEAD_N - TAIL_N )); [ "$ELIDED" -lt 0 ] && ELIDED=0

SUMMARY=$(printf '[output-sandbox] %s lines / %s chars — full output saved to %s\n--- head (%s) ---\n%s\n… %s lines elided (retrieve: grep/sed/less %s) …\n--- tail (%s) ---\n%s' \
  "$LINES" "$CHARS" "$LOG" "$HEAD_N" "$HEAD" "$ELIDED" "$LOG" "$TAIL_N" "$TAIL")

jq -n --arg out "$SUMMARY" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse", updatedToolOutput:$out}}' 2>/dev/null || exit 0
exit 0
