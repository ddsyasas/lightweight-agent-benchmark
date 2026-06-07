#!/usr/bin/env bash
# usage: ./scripts/bench_smolagents.sh <task>
# smolagents is a library: each trial is a fresh `python smol_runner.py` process,
# so trials are independent with no session state to clear (no cross-process memory).
set -u

AGENT="smolagents"
BACKEND="cloud"
TRIALS=5
PY="$HOME/smol-venv/bin/python"
RUNNER="$HOME/agent-bench/scripts/smol_runner.py"
WORKSPACE="$HOME/smolagents-work"
CSV="results/data.csv"
TASK="${1:-task1}"

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
