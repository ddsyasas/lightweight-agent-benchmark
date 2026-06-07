# Lightweight Agent Benchmark on a Raspberry Pi 4

A small, **reproducible** benchmark comparing 2026-era ultra-lightweight AI-agent
frameworks on the **same constrained edge hardware** — a 2 GB Raspberry Pi 4 — holding
the language model constant, so that **framework overhead** (memory footprint,
agent-loop latency, out-of-the-box capability) is separated from inference cost.

> **Research question:** Which lightweight agent framework runs best on a ~$35 Raspberry
> Pi, and can any of them run fully offline?

## Frameworks tested

| Agent | Language | Result |
|---|---|---|
| **ZeroClaw** | Rust | benchmarked — lightest (~20 MB) |
| **PicoClaw** | Go | benchmarked (~31 MB) |
| **smolagents** | Python (library) | benchmarked (~90 MB) |
| **NanoBot** | Python | benchmarked (~130 MB) |
| **Agent Zero** | Python | excluded (won't install on Python 3.13, no headless mode, heavyweight Docker stack) |

## Hardware

Raspberry Pi 4 Model B Rev 1.5 · **2 GB RAM** (1846 MB) · 128 GB SD (117 GB usable) ·
4-core ARM Cortex-A72 (aarch64) · Debian 13 (trixie) / Raspberry Pi OS · Python 3.13.5.
All measurements taken **on the Pi**; GNU `/usr/bin/time` for wall-clock and peak RSS.

## Tasks (5, programmatic pass/fail, n = 5 trials each)

| ID | Tests | Pass check |
|---|---|---|
| T1 | basic tool call | `result.txt` == `BENCHMARK_OK` |
| T2 | chaining + state | read `input.txt`(14) ×3 → `output.txt` == 42 |
| T3 | using tool output | count lines in `data.txt`(7) → `count.txt` == 7 |
| T4 | robustness | append `done` to a missing `log.txt` |
| T5 | persistent memory | store a fact, then recall it in a fresh session |

Metrics per trial: **success** (programmatic), **seconds** (wall clock), **peak_mem_mb**
(max RSS). Report the **median** + range over n=5; memory is the trustworthy axis, time
is noisy (network variance). The same language model is held constant across all agents.

## Experiments & headline results

**1. Cloud backend** (4 agents × 5 tasks × 5 trials = 100 trials). Memory tracks the
runtime cleanly: **ZeroClaw ~20 MB < PicoClaw ~31 MB < smolagents ~90 MB < NanoBot
~130 MB** — compiled (Rust/Go) agents are 3–6× lighter than Python. Success: 3/4 agents
100%; NanoBot fails T5 (its long-term memory consolidates asynchronously).

**2. Offline / local backend** (Ollama; Qwen2.5-1.5B and SmolLM2-360M). **0/8 agent×model
combinations completed even T1.** The bottleneck is speed/capability, not RAM: the capable
1.5B model is too slow (the agents' default HTTP timeouts fire before it responds), and the
fast 360M model has no tool-calling support and is too weak for code. *The model runs
offline; the agents do not.*

**3. Concurrency / fleet density** (N = 1,2,4,8 concurrent instances per agent, cloud).
**All agents run 8 concurrent instances at 100% success**, RAM grows linearly, and
compiled agents stay flat on latency. Compiled (Rust/Go) agents pack **~10–20× denser**
than Python ones (~5–10 MB vs ~70–110 MB per instance).

## Repository layout

```
scripts/            benchmark harness (shell) + smolagents runner (smol_runner.py)
analyze_all.py      summary-stats / comparison tables from the CSVs
results/            raw data — one CSV per experiment (see Data Files below)
agents/             per-agent install notes, versions, quirks
config-templates/   how to point each agent at an OpenAI-compatible endpoint (no keys)
figures/            generated figures
paper/              the write-up (added when finalized)
```

## Data files

| File | Rows | Experiment |
|---|---|---|
| `results/agent-bench_all-agents_cloud_2026-06-07.csv` | 100 | Cloud — 4 agents × 5 tasks × 5 trials (primary) |
| `results/zeroclaw_rerun_cloud_2026-06-07.csv` | 25 | Cloud — ZeroClaw reproducibility re-run |
| `results/local_probe_qwen2.5-1.5b_2026-06-07.csv` | 4 | Offline — Qwen2.5-1.5B, T1/agent |
| `results/local_probe_smollm2-360m_2026-06-07.csv` | 4 | Offline — SmolLM2-360M, T1/agent |
| `results/scaling_batch_cloud_2026-06-07.csv` | 16 | Concurrency — per (agent, N): RAM/latency/success |
| `results/scaling_instances_cloud_2026-06-07.csv` | 60 | Concurrency — per-instance latency |
| `results/agent-bench_zeroclaw-vs-picoclaw_cloud_2026-06-07.csv` | 50 | (historical 2-agent subset — superseded) |

**Schemas:** trial files = `agent,backend,task,trial,success,seconds,peak_mem_mb,notes`;
`scaling_batch` = `agent,backend,n,baseline_ram_mb,peak_ram_mb,delta_ram_mb,passed,wall_s`;
`scaling_instances` = `agent,backend,n,instance,success,seconds`.

## Reproduce

1. Install each agent on the Pi (see `agents/*.md`).
2. Point each at the same OpenAI-compatible model + key (see `config-templates/`).
3. Run the harness from the project dir:
   ```bash
   ./scripts/bench.sh task1 ; ./scripts/bench.sh task2 ; ./scripts/bench.sh task3
   ./scripts/bench.sh task4 ; ./scripts/bench_mem.sh        # repeat per agent script
   python3 analyze_all.py
   ```
The harness is deterministic apart from model/network latency.

## License

MIT — see [LICENSE](LICENSE).
