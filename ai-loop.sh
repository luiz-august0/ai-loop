#!/usr/bin/env bash

set -euo pipefail

PROMPT="$1"
COMPLETION_PROMISE="${2:-}"
MAX_ITERATIONS="${3:-10}"
CLI_MODE="${4:-claude}"   # claude | devin | multi
SAVE_HISTORY="${5:-true}"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="ai-loop-$TIMESTAMP.log"

ITERATION=1
CONTEXT=""

echo "🚀 Starting AI loop..."
echo "Mode: $CLI_MODE"
echo "----------------------------------------"

# ------------------------
# CLI RUNNERS
# ------------------------

run_claude() {
  local input="$1"
  claude --print --dangerously-skip-permissions "$input"
}

run_devin() {
  local input="$1"
  devin --permission-mode dangerous -p "$input"
}

run_cli() {
  local input="$1"
  local cli="$2"

  case "$cli" in
    claude)
      run_claude "$input"
      ;;
    devin)
      run_devin "$input"
      ;;
    *)
      echo "❌ Unknown CLI: $cli"
      exit 1
      ;;
  esac
}

# ------------------------
# LOOP
# ------------------------

while [ "$ITERATION" -le "$MAX_ITERATIONS" ]; do
  echo ""
  echo "🔁 Iteration $ITERATION"
  echo "----------------------------------------"

  CURRENT_CLI="$CLI_MODE"

  if [ "$CLI_MODE" == "multi" ]; then
    if (( ITERATION % 2 == 0 )); then
      CURRENT_CLI="claude"
    else
      CURRENT_CLI="devin"
    fi
  fi

  echo "🤖 Using: $CURRENT_CLI"

  FULL_PROMPT="$PROMPT"

  if [ -n "$CONTEXT" ]; then
    FULL_PROMPT="$FULL_PROMPT

Previous output:
$CONTEXT

Refine, improve, and continue."
  fi

  OUTPUT=$(run_cli "$FULL_PROMPT" "$CURRENT_CLI" | tee /dev/stderr)

  # ------------------------
  # SAVE HISTORY
  # ------------------------
  if [ "$SAVE_HISTORY" == "true" ]; then
    {
      echo "=============================="
      echo "Iteration: $ITERATION"
      echo "Agent: $CURRENT_CLI"
      echo "------------------------------"
      echo "$OUTPUT"
      echo ""
    } >> "$LOG_FILE"
  fi

  # ------------------------
  # COMPLETION CHECK
  # ------------------------
  if [ -n "$COMPLETION_PROMISE" ]; then
    if echo "$OUTPUT" | grep -q "$COMPLETION_PROMISE"; then
      echo "✅ Completion reached!"
      exit 0
    fi
  fi

  # ------------------------
  # STUCK DETECTION
  # ------------------------
  if [ "$OUTPUT" == "$CONTEXT" ]; then
    echo "🧠 Stuck detected. Breaking."
    break
  fi

  CONTEXT="$OUTPUT"
  ITERATION=$((ITERATION + 1))
done

echo "⚠️ Loop ended without completion."
exit 1