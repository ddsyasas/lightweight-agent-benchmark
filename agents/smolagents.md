# smolagents — install notes, version, quirks (benchmark agent #4)

## Identity
- **Framework:** smolagents (Python, Hugging Face), https://github.com/huggingface/smolagents
- **Version:** 1.26.0 (PyPI), openai SDK 2.41.0
- **Python:** 3.13.5 in a dedicated venv (`~/smol-venv`).

## Install
```bash
python3 -m venv ~/smol-venv
~/smol-venv/bin/pip install -U pip
~/smol-venv/bin/pip install smolagents openai
```
Installed cleanly on aarch64 / Py3.13.

## KEY DIFFERENCE — it's a LIBRARY, not a turnkey agent
smolagents has no CLI agent and **ships no file tools**. To benchmark it we wrote a
small runner (`scripts/smol_runner.py`) that:
- builds `OpenAIModel(model_id="google/gemini-3.1-pro-preview",
  api_base="https://openrouter.ai/api/v1", api_key=<same key as zeroclaw>)`,
- builds a **`CodeAgent`** (smolagents' flagship default — it writes & executes
  Python) equipped with minimal `write_file` / `read_file` / `append_file` tools
  and `additional_authorized_imports=["os","pathlib"]`,
- runs one prompt per process: `python smol_runner.py "<prompt>"`.
Providing file tools is a documented harness adaptation — itself a finding: smolagents
requires assembly that the turnkey agents (ZeroClaw/PicoClaw/NanoBot) do not.

## Run command (per trial)
```bash
OPENROUTER_API_KEY=... SMOL_MODEL=google/gemini-3.1-pro-preview \
SMOL_WS=~/smolagents-work  ~/smol-venv/bin/python scripts/smol_runner.py "<prompt>"
```
Workspace: `~/smolagents-work` (runner chdirs here; files land here).

## Out-of-the-box behavior (findings)
- **Writes files fine** — CodeAgent emits `write_file(...)` + `final_answer(...)`.
- **Memory footprint ~89–92 MB** (flat) — Python + openai + smolagents; lighter than
  NanoBot (~130 MB) because it has fewer deps and no git-backed store. RSS of the
  single Python process (`/usr/bin/time %M`), same method as all agents.
- **No session/conversation persistence across processes** → trials are naturally
  independent; nothing to clear (unlike PicoClaw/NanoBot).
- **Latency** mostly 7–35 s but with occasional large outliers (one 143 s run on T2)
  — the CodeAgent loop sometimes takes many steps. n=5 median absorbs this.

## T5 (memory) result: PASS 5/5 — but via filesystem, not a memory feature
smolagents has **no built-in persistent memory**. It passed T5 by improvising:
the store call wrote `memory.txt` ("Project ID: ZX-9"); the recall call (fresh
process) ran `os.listdir('.')`, discovered `memory.txt`, read it, and returned ZX-9.
This is **emergent persistence from code execution + a persistent workspace**, a real
architectural distinction from the tool-calling agents that use a dedicated memory
store. Report it as such (it is a legitimate pass under the programmatic check, but
the mechanism differs). Note: the workspace persists between the store and recall
calls (not reset), which is what makes the file discoverable.

## Scripts
- `scripts/smol_runner.py` (the agent)
- `scripts/bench_smolagents.sh <task1..task4>`
- `scripts/bench_smolagents_mem.sh` (task5)
