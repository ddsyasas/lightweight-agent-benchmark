#!/usr/bin/env bash
# task5 (persistent memory) for NanoBot.
# Session cleared before BOTH store and recall so recall must use the memory store
# (memory/MEMORY.md), not chat history. Memory reset to pristine once before suite.
# NOTE: NanoBot consolidates long-term memory asynchronously ("dream", intervalH=2),
# so immediate cross-session recall is expected to FAIL — that is a recorded result.
set -u
AGENT="nanobot"; BACKEND="cloud"; TASK="task5"; TRIALS=5
NB="$HOME/nanobot-venv/bin/nanobot"
WORKSPACE="$HOME/.nanobot/workspace"
SESSIONS="$WORKSPACE/sessions"
CSV="results/data.csv"

[ -f "$CSV" ] || echo "agent,backend,task,trial,success,seconds,peak_mem_mb,notes" > "$CSV"

# reset memory to pristine scaffold once before the suite
cat > "$WORKSPACE/memory/MEMORY.md" << 'PRISTINE'
# Long-term Memory

This file stores important information that should persist across sessions.

## User Information

(Important facts about the user)

## Preferences

(User preferences learned over time)

## Project Context

(Information about ongoing projects)

## Important Notes

(Things to remember)

---

*This file is automatically updated by nanobot when important information should be remembered.*
PRISTINE
: > "$WORKSPACE/memory/history.jsonl" 2>/dev/null || true

run_agent () {
  rm -f "$SESSIONS"/*.jsonl 2>/dev/null
  /usr/bin/time -f "%e %M" -o results/_time.txt \
    "$NB" agent -m "$1" --no-markdown >"$2" 2>>results/_agent_err.log
}

for i in $(seq 1 "$TRIALS"); do
  OUT="results/${AGENT}_${TASK}_run${i}.out"
  run_agent "Please remember this fact and save it to memory: my project ID is ZX-9." "results/_store.out"
  run_agent "What is my project ID? Look it up in your memory and tell me." "$OUT"

  read SECS KB < results/_time.txt
  MB=$(awk -v k="$KB" 'BEGIN{printf "%.1f", k/1024}')
  grep -q "ZX-9" "$OUT" 2>/dev/null && SUCCESS="pass" || SUCCESS="fail"

  echo "${AGENT},${BACKEND},${TASK},${i},${SUCCESS},${SECS},${MB},memory-recall" >> "$CSV"
  echo "trial ${i}: ${SUCCESS}  ${SECS}s  ${MB}MB"
done
rm -f results/_time.txt results/_store.out
echo "Done with task5."
