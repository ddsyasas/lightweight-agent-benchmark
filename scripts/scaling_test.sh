#!/usr/bin/env bash
# N x same-agent concurrency scaling, CLOUD (OpenRouter gemini), task T1.
# For each agent and each N in {1,2,4,8}: launch N instances concurrently, measure
# per-instance latency + success, and peak combined system RAM during the batch.
set -u
cd /home/steven/agent-bench
INST=results/scaling_instances_2026-06-07.csv
BATCH=results/scaling_batch_2026-06-07.csv
echo "agent,backend,n,instance,success,seconds" > "$INST"
echo "agent,backend,n,baseline_ram_mb,peak_ram_mb,delta_ram_mb,passed,wall_s" > "$BATCH"
KEY=$(grep -oE 'sk-or-v1-[A-Za-z0-9_-]+' ~/.zeroclaw/config.toml | head -1)

prompt_for(){ printf 'Create a file named %s containing exactly the text BENCHMARK_OK and nothing else' "$1"; }
wsdir(){ case "$1" in zeroclaw) echo ~/.zeroclaw/workspace;; picoclaw) echo ~/picoclaw/workspace;; nanobot) echo ~/.nanobot/workspace;; smolagents) echo ~/smolagents-work;; esac; }

launch(){  # agent id
  local agent="$1" id="$2" rf tf out p
  rf="result_${agent}_${id}.txt"; tf="results/_t_${agent}_${id}"; out="results/_o_${agent}_${id}.out"
  p="$(prompt_for "$rf")"
  case "$agent" in
    zeroclaw)  /usr/bin/time -f "%e" -o "$tf" ~/.cargo/bin/zeroclaw agent -m "$p" --session-state-file "results/_zss_${id}.json" >"$out" 2>&1 ;;
    picoclaw)  /usr/bin/time -f "%e" -o "$tf" picoclaw --no-color agent -s "scale-$id" -m "$p" >"$out" 2>&1 ;;
    nanobot)   /usr/bin/time -f "%e" -o "$tf" ~/nanobot-venv/bin/nanobot agent -s "scale-$id" -m "$p" --no-markdown >"$out" 2>&1 ;;
    smolagents) SMOL_API_BASE=https://openrouter.ai/api/v1 SMOL_MODEL=google/gemini-3.1-pro-preview OPENROUTER_API_KEY="$KEY" SMOL_WS=/home/steven/smolagents-work \
                 /usr/bin/time -f "%e" -o "$tf" ~/smol-venv/bin/python ~/agent-bench/scripts/smol_runner.py "$p" >"$out" 2>&1 ;;
  esac
}

for agent in zeroclaw picoclaw nanobot smolagents; do
  WS=$(wsdir "$agent")
  for N in 1 2 4 8; do
    rm -f "$WS"/result_${agent}_${N}_*.txt 2>/dev/null
    base=$(free -m | awk '/Mem:/{print $3}')
    ( while :; do free -m | awk '/Mem:/{print $3}'; sleep 0.4; done ) > results/_ram.tmp 2>/dev/null &
    SAMP=$!
    t0=$(date +%s); pids=""
    for i in $(seq 1 $N); do launch "$agent" "${N}_${i}" & pids="$pids $!"; done
    wait $pids 2>/dev/null
    t1=$(date +%s)
    kill $SAMP 2>/dev/null; wait $SAMP 2>/dev/null
    pk=$(sort -n results/_ram.tmp 2>/dev/null | tail -1); pk=${pk:-$base}
    passed=0
    for i in $(seq 1 $N); do
      id="${N}_${i}"; s=$(tail -1 "results/_t_${agent}_${id}" 2>/dev/null); s=${s:-NA}
      if grep -q BENCHMARK_OK "$WS/result_${agent}_${id}.txt" 2>/dev/null; then ok=pass; passed=$((passed+1)); else ok=fail; fi
      echo "$agent,cloud,$N,$i,$ok,$s" >> "$INST"
    done
    echo "$agent,cloud,$N,$base,$pk,$((pk-base)),$passed,$((t1-t0))" >> "$BATCH"
    echo ">>> $agent N=$N: passed=$passed/$N  peakRAM=${pk}MB (Δ$((pk-base)))  wall=$((t1-t0))s"
  done
done
rm -f results/_ram.tmp results/_t_* results/_zss_* 2>/dev/null
echo "=== BATCH SUMMARY ==="; column -t -s, "$BATCH"
echo "SCALING_DONE"
