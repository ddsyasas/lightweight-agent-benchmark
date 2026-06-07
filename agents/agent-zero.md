# Agent Zero — NEGATIVE RESULT (benchmark agent #5, not benchmarkable on this rig)

## Identity
- **Framework:** Agent Zero (Python), https://github.com/frdel/agent-zero
- **Attempted:** 2026-06-07 on Raspberry Pi 4, 2 GB RAM, aarch64, Python 3.13.5.

## Outcome: could not be benchmarked. Logged as a result per runbook §12 step 7.

Three independent, concrete blockers — any one is disqualifying for this harness:

### 1. Dependency install fails on the Pi's Python (3.13)
`pip install -r requirements.txt` cannot resolve:
```
ERROR: Could not find a version that satisfies the requirement kokoro>=0.9.2
  (kokoro 0.9.x Requires-Python >=3.10,<3.13)
```
Agent Zero pins `kokoro>=0.9.2` (a TTS dep) which **does not support Python 3.13**.
Raspberry Pi OS (Debian 13 trixie) ships Python 3.13, so the stack won't install
without first sideloading an older Python (3.12).

### 2. No headless / non-interactive interface
Entry points are `run_ui.py` (Flask web UI) and `run_tunnel.py` only — there is **no
CLI single-prompt mode** (no `run_cli.py`). The benchmark harness measures a one-shot
non-interactive command per trial under `/usr/bin/time`. Agent Zero is a long-lived
web/Docker server; driving it would require its HTTP API and would measure a
persistent container's RSS, not per-invocation footprint — not comparable to the
other agents.

### 3. Heavyweight dependency stack — not a lightweight edge agent
`requirements.txt` pulls `torch` (via `sentence-transformers==3.0.1`),
`unstructured[all-docs]==0.16.23`, `playwright==1.52.0` (Chromium), and
`faiss-cpu==1.11.0`. This is designed to run inside Agent Zero's Docker image
("one container ships a full Linux system with a desktop"), not on a 2 GB Pi. It
contradicts the benchmark's scope (ultra-lightweight agents: ZeroClaw ~20 MB,
PicoClaw ~31 MB, smolagents ~90 MB, NanoBot ~130 MB).

## Conclusion
Agent Zero is a heavyweight, Docker-oriented, web-UI framework — not an
ultra-lightweight edge agent. On current Raspberry Pi OS it cannot be installed
(Python 3.13 incompatibility) and offers no headless interface compatible with the
benchmark's per-invocation measurement. **Excluded from the comparison as a
documented negative result.**

### If a future attempt is wanted
Would require: sideload Python 3.12 (pyenv/deadsnakes) → install the full heavy stack
(expect long builds + possible OOM on 2 GB) → write a custom headless driver against
Agent Zero's internal API (`agent.py`/`initialize.py`) since no CLI exists → and even
then memory numbers would not be per-invocation-comparable. Recommended only if the
paper specifically needs a heavyweight contrast point.
