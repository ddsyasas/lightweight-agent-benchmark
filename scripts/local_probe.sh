#!/usr/bin/env bash
# Lean LOCAL probe: one T1 trial per agent against qwen-ctx (Qwen2.5-1.5B @ num_ctx=10240)
# via Ollama on localhost. Captures pass/fail, wall seconds, agent peak RSS, and system RAM.
# Per-agent 20-min timeout so a stuck/swapping agent can't block the batch.
set -u
cd /home/steven/agent-bench
CSV=results/local_probe_2026-06-07.csv
echo "agent,backend,task,trial,success,seconds,peak_mem_mb,notes" > "$CSV"
MODEL=qwen-ctx
TO=1200
P="Create a file named result.txt containing exactly the text BENCHMARK_OK and nothing else"

runone(){  # name  workspace_result_file  expected  -- agent command...
  local name="$1" wf="$2" exp="$3"; shift 3
  rm -f results/_lt.txt; rm -f "$wf" 2>/dev/null
  echo ">>> $name starting $(date +%H:%M:%S)"
  timeout $TO /usr/bin/time -f "%e %M" -o results/_lt.txt "$@" > "results/local_${name}_t1.out" 2>&1
  local rc=$?
  local ok; if grep -q "$exp" "$wf" 2>/dev/null; then ok=pass; else ok=fail; fi
  local s mb note=probe
  if [ -s results/_lt.txt ]; then read s kb < results/_lt.txt; mb=$(awk -v k="$kb" 'BEGIN{printf "%.1f",k/1024}'); else s=">${TO}"; mb=NA; fi
  [ $rc -eq 124 ] && note=probe-timeout
  echo "$name,local,task1,1,$ok,$s,$mb,$note" >> "$CSV"
  free -m | awk -v n="$name" '/Mem:/{print "    "n" system RAM: used "$3" MB, available "$7" MB"}'
  echo "<<< $name: $ok  ${s}s  ${mb}MB  rc=$rc"
}

export SMOL_API_BASE=http://localhost:11434/v1 SMOL_MODEL=$MODEL OPENROUTER_API_KEY=ollama SMOL_WS=/home/steven/smolagents-work
runone smolagents /home/steven/smolagents-work/result.txt BENCHMARK_OK ~/smol-venv/bin/python ~/agent-bench/scripts/smol_runner.py "$P"

rm -f /home/steven/picoclaw/workspace/sessions/*.jsonl 2>/dev/null
runone picoclaw /home/steven/picoclaw/workspace/result.txt BENCHMARK_OK picoclaw --no-color agent --model qwen-local -m "$P"

rm -f /home/steven/.nanobot/workspace/sessions/*.jsonl 2>/dev/null
runone nanobot /home/steven/.nanobot/workspace/result.txt BENCHMARK_OK ~/nanobot-venv/bin/nanobot agent -c /home/steven/.nanobot/config.local.json -m "$P" --no-markdown

runone zeroclaw /home/steven/.zeroclaw/workspace/result.txt BENCHMARK_OK ~/.cargo/bin/zeroclaw agent -p ollama --model $MODEL -m "$P"

echo "=== PROBE RESULTS ==="; column -t -s, "$CSV"
echo "PROBE_DONE"
