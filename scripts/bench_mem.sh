#!/usr/bin/env bash
set -u
AGENT="zeroclaw"; BACKEND="cloud"; TASK="task5"; TRIALS=5
WORKSPACE="$HOME/.zeroclaw/workspace"; CSV="results/data.csv"

[ -f "$CSV" ] || echo "agent,backend,task,trial,success,seconds,peak_mem_mb,notes" > "$CSV"

run_agent () {
  /usr/bin/time -f "%e %M" -o results/_time.txt \
    zeroclaw agent -m "$1" >"$2" 2>>results/_agent_err.log
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
