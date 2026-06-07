#!/usr/bin/env bash
# usage: local_probe_model.sh <ollama_model> <csv_suffix>
# Points all 4 agents at <ollama_model> via local Ollama, runs one T1 each,
# records pass/fail + wall seconds + agent peak RSS to results/local_probe_<suffix>.csv
set -u
cd /home/steven/agent-bench
MODEL="${1:-qwen-ctx}"
SUF="${2:-$MODEL}"
CSV="results/local_probe_${SUF}.csv"
echo "agent,backend,task,trial,success,seconds,peak_mem_mb,notes" > "$CSV"
TO=1200
P="Create a file named result.txt containing exactly the text BENCHMARK_OK and nothing else"

echo "### pointing all agents at model: $MODEL"
python3 - "$MODEL" <<'PY'
import json,sys
m=sys.argv[1]
p="/home/steven/picoclaw/config.json"; c=json.load(open(p))
for e in c["model_list"]:
    if e.get("model_name")=="qwen-local": e["model"]=m
json.dump(c,open(p,"w"),indent=2)
p="/home/steven/.nanobot/config.local.json"; c=json.load(open(p))
c["agents"]["defaults"]["model"]=m; json.dump(c,open(p,"w"),indent=2)
PY
# zeroclaw: replace model only inside the [providers.models.ollama] block
sed -i "/\[providers.models.ollama\]/,/^\[/ s|^model = .*|model = \"$MODEL\"|" /home/steven/.zeroclaw/config.toml

runone(){  # name  workspace_result_file  expected  -- agent command...
  local name="$1" wf="$2" exp="$3"; shift 3
  rm -f results/_lt.txt; rm -f "$wf" 2>/dev/null
  echo ">>> $name starting $(date +%H:%M:%S)"
  timeout $TO /usr/bin/time -f "%e %M" -o results/_lt.txt "$@" > "results/local_${name}_${SUF}.out" 2>&1
  local rc=$?
  local ok; if grep -q "$exp" "$wf" 2>/dev/null; then ok=pass; else ok=fail; fi
  local s mb note=probe
  if [ -s results/_lt.txt ]; then read s mb < <(tail -1 results/_lt.txt); mb=$(awk -v k="$mb" 'BEGIN{printf "%.1f",k/1024}'); else s=">${TO}"; mb=NA; fi
  [ $rc -eq 124 ] && note=probe-timeout
  echo "$name,local,task1,1,$ok,$s,$mb,$note" >> "$CSV"
  free -m | awk -v n="$name" '/Mem:/{print "    "n" sys RAM: used "$3" MB, avail "$7" MB"}'
  echo "<<< $name: $ok  ${s}s  ${mb}MB  rc=$rc"
}

export SMOL_API_BASE=http://localhost:11434/v1 SMOL_MODEL=$MODEL OPENROUTER_API_KEY=ollama SMOL_WS=/home/steven/smolagents-work
runone smolagents /home/steven/smolagents-work/result.txt BENCHMARK_OK ~/smol-venv/bin/python ~/agent-bench/scripts/smol_runner.py "$P"

rm -f /home/steven/picoclaw/workspace/sessions/*.jsonl 2>/dev/null
runone picoclaw /home/steven/picoclaw/workspace/result.txt BENCHMARK_OK picoclaw --no-color agent --model qwen-local -m "$P"

rm -f /home/steven/.nanobot/workspace/sessions/*.jsonl 2>/dev/null
runone nanobot /home/steven/.nanobot/workspace/result.txt BENCHMARK_OK ~/nanobot-venv/bin/nanobot agent -c /home/steven/.nanobot/config.local.json -m "$P" --no-markdown

runone zeroclaw /home/steven/.zeroclaw/workspace/result.txt BENCHMARK_OK ~/.cargo/bin/zeroclaw agent -p ollama --model $MODEL -m "$P"

echo "=== RESULTS ($MODEL) ==="; column -t -s, "$CSV"
echo "PROBE_DONE"
