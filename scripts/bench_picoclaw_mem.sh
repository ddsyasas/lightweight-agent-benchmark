#!/usr/bin/env bash
# task5 (persistent memory) for PicoClaw.
# Session is cleared before BOTH the store and the recall call, so recall can only
# succeed via PicoClaw's actual memory store (workspace/memory), not conversation
# history. This matches zeroclaw's load_session_context=false behavior.
# Memory is reset to its pristine scaffold ONCE before the suite (matches zeroclaw:
# no memory reset between trials).
set -u
AGENT="picoclaw"; BACKEND="cloud"; TASK="task5"; TRIALS=5
WORKSPACE="$HOME/picoclaw/workspace"
SESSIONS="$WORKSPACE/sessions"
CSV="results/data.csv"

export PICOCLAW_HOME="$HOME/picoclaw"

[ -f "$CSV" ] || echo "agent,backend,task,trial,success,seconds,peak_mem_mb,notes" > "$CSV"

# --- reset memory to pristine scaffold once before the suite ---
cat > "$WORKSPACE/memory/MEMORY.md" << 'PRISTINE'
# Long-term Memory

This file stores important information that should persist across sessions.

## User Information

(Important facts about user)

## Preferences

(User preferences learned over time)

## Important Notes

(Things to remember)

## Configuration

- Model preferences
- Channel settings
- Skills enabled
PRISTINE

run_agent () {
  rm -f "$SESSIONS"/*.jsonl 2>/dev/null   # fresh session before each call
  /usr/bin/time -f "%e %M" -o results/_time.txt \
    picoclaw --no-color agent -m "$1" >"$2" 2>>results/_agent_err.log
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
