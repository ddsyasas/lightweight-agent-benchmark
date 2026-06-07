#!/usr/bin/env bash
# usage: ./scripts/bench_nanobot.sh <task>   e.g. ./scripts/bench_nanobot.sh task2
# Mirrors bench.sh; sessions cleared before each call for independent trials
# (matches zeroclaw's load_session_context=false / context-free per trial).
set -u

AGENT="nanobot"
BACKEND="cloud"
TRIALS=5
NB="$HOME/nanobot-venv/bin/nanobot"
WORKSPACE="$HOME/.nanobot/workspace"
SESSIONS="$WORKSPACE/sessions"
CSV="results/data.csv"
TASK="${1:-task1}"

[ -f "$CSV" ] || echo "agent,backend,task,trial,success,seconds,peak_mem_mb,notes" > "$CSV"

run_agent () {
  rm -f "$SESSIONS"/*.jsonl 2>/dev/null   # fresh session: no prior conversation context
  /usr/bin/time -f "%e %M" -o results/_time.txt \
    "$NB" agent -m "$1" --no-markdown >"$2" 2>>results/_agent_err.log
}

for i in $(seq 1 "$TRIALS"); do
  OUT="results/${AGENT}_${TASK}_run${i}.out"

  case "$TASK" in
    task1)
      rm -f "$WORKSPACE/result.txt"
      run_agent "Create a file named result.txt containing exactly the text BENCHMARK_OK and nothing else" "$OUT"
      grep -q "BENCHMARK_OK" "$WORKSPACE/result.txt" 2>/dev/null && OK=1 || OK=0 ;;
    task2)
      rm -f "$WORKSPACE/output.txt"; echo "14" > "$WORKSPACE/input.txt"
      run_agent "Read the number written in the file input.txt, multiply it by 3, and write only the resulting number to a file named output.txt" "$OUT"
      grep -q "42" "$WORKSPACE/output.txt" 2>/dev/null && OK=1 || OK=0 ;;
    task3)
      rm -f "$WORKSPACE/count.txt"
      printf 'alpha\nbravo\ncharlie\ndelta\necho\nfoxtrot\ngolf\n' > "$WORKSPACE/data.txt"
      run_agent "Count how many lines are in the file data.txt, then write only that number to a file named count.txt" "$OUT"
      grep -q "7" "$WORKSPACE/count.txt" 2>/dev/null && OK=1 || OK=0 ;;
    task4)
      rm -f "$WORKSPACE/log.txt"
      run_agent "Append a new line containing the word done to a file named log.txt" "$OUT"
      grep -q "done" "$WORKSPACE/log.txt" 2>/dev/null && OK=1 || OK=0 ;;
    *)
      echo "Unknown task: $TASK"; exit 1 ;;
  esac

  read SECS KB < results/_time.txt
  MB=$(awk -v k="$KB" 'BEGIN{printf "%.1f", k/1024}')
  [ "$OK" = "1" ] && SUCCESS="pass" || SUCCESS="fail"

  echo "${AGENT},${BACKEND},${TASK},${i},${SUCCESS},${SECS},${MB},auto" >> "$CSV"
  echo "trial ${i}: ${SUCCESS}  ${SECS}s  ${MB}MB"
done

rm -f results/_time.txt
echo "Done with ${TASK}. Appended ${TRIALS} rows to ${CSV}"
