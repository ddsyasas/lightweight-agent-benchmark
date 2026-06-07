#!/usr/bin/env bash
# Fresh ZeroClaw re-run (task5, memory). Mirrors the original bench_mem.sh; full
# binary path + separate CSV. ZeroClaw recalls from its own memory store
# (load_session_context=false), store then recall, no reset between them.
set -u
AGENT="zeroclaw"; BACKEND="cloud"; TASK="task5"; TRIALS=5
ZC="$HOME/.cargo/bin/zeroclaw"
WORKSPACE="$HOME/.zeroclaw/workspace"
CSV="results/zeroclaw_rerun_2026-06-07.csv"

[ -f "$CSV" ] || echo "agent,backend,task,trial,success,seconds,peak_mem_mb,notes" > "$CSV"

run_agent () {
  /usr/bin/time -f "%e %M" -o results/_time.txt \
    "$ZC" agent -m "$1" >"$2" 2>>results/_agent_err.log
}

for i in $(seq 1 "$TRIALS"); do
  OUT="results/${AGENT}_rerun_${TASK}_run${i}.out"
  run_agent "Please remember this fact and save it to memory: my project ID is ZX-9." "results/_store.out"
  run_agent "What is my project ID? Look it up in your memory and tell me." "$OUT"

  read SECS KB < results/_time.txt
  MB=$(awk -v k="$KB" 'BEGIN{printf "%.1f", k/1024}')
  grep -q "ZX-9" "$OUT" 2>/dev/null && SUCCESS="pass" || SUCCESS="fail"

  echo "${AGENT},${BACKEND},${TASK},${i},${SUCCESS},${SECS},${MB},memory-recall-rerun" >> "$CSV"
  echo "trial ${i}: ${SUCCESS}  ${SECS}s  ${MB}MB"
done
rm -f results/_time.txt results/_store.out
echo "Done with task5."
