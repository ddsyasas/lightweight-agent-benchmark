#!/usr/bin/env bash
# task5 (persistent memory) for smolagents.
# smolagents has NO built-in cross-session/persistent memory: each call is a fresh
# process and the recall agent has no knowledge of the store agent's run. Expected
# to FAIL — recorded as a capability result (not a harness bug).
set -u
AGENT="smolagents"; BACKEND="cloud"; TASK="task5"; TRIALS=5
PY="$HOME/smol-venv/bin/python"
RUNNER="$HOME/agent-bench/scripts/smol_runner.py"
WORKSPACE="$HOME/smolagents-work"
CSV="results/data.csv"

export OPENROUTER_API_KEY="$(grep -oE 'sk-or-v1-[A-Za-z0-9_-]+' "$HOME/.zeroclaw/config.toml" | head -1)"
export SMOL_MODEL="google/gemini-3.1-pro-preview"
export SMOL_WS="$WORKSPACE"
mkdir -p "$WORKSPACE"

[ -f "$CSV" ] || echo "agent,backend,task,trial,success,seconds,peak_mem_mb,notes" > "$CSV"

run_agent () {
  /usr/bin/time -f "%e %M" -o results/_time.txt \
    "$PY" "$RUNNER" "$1" >"$2" 2>>results/_agent_err.log
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
