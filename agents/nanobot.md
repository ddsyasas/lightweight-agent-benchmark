# NanoBot — install notes, version, quirks (benchmark agent #3)

## Identity
- **Framework:** NanoBot (Python), https://github.com/HKUDS/nanobot
- **Version:** v0.2.1 (PyPI package `nanobot-ai`)
- **Python:** 3.13.5 in a dedicated venv (`~/nanobot-venv`); Pi is PEP-668 externally-managed so a venv is required.

## Install
```bash
python3 -m venv ~/nanobot-venv
~/nanobot-venv/bin/pip install -U pip
~/nanobot-venv/bin/pip install nanobot-ai
~/nanobot-venv/bin/nanobot onboard      # scaffolds ~/.nanobot/config.json + workspace
```
Installed cleanly on aarch64 / Py3.13 (no build issues).

## Config / workspace
- Config: `~/.nanobot/config.json`. Workspace: `~/.nanobot/workspace`.
- Session store: `~/.nanobot/workspace/sessions/cli_direct.jsonl`.
- Long-term memory: `~/.nanobot/workspace/memory/MEMORY.md` (+ `history.jsonl`).
- Uses a **git-backed memory store** (workspace is a git repo).

## Cloud model (held constant — fairness)
- `providers.openrouter.apiKey` = (same key as zeroclaw, from `~/.zeroclaw/config.toml`).
- `agents.defaults.provider = "openrouter"`, `agents.defaults.model = "google/gemini-3.1-pro-preview"`.

## Non-interactive run command
```bash
~/nanobot-venv/bin/nanobot agent -m "<prompt>" --no-markdown
# flags: -m message, -s session (default cli:direct), -w workspace, -c config
```

## Out-of-the-box behavior (findings)
- **Writes files freely** via its `write_file` tool — no approval/permission step
  (like PicoClaw; unlike secure-by-default ZeroClaw).
- **Memory footprint ~130 MB** (flat across tasks) — Python interpreter + deps;
  ~6.5x ZeroClaw, ~4x PicoClaw. Measured as RSS of the single Python process
  (`/usr/bin/time %M`), same method as the other agents.
- **Session persistence:** ON by default (a fresh `agent -m` call recalls the prior
  prompt). Neutralized for the benchmark by clearing `sessions/*.jsonl` before each
  call — same fairness control as PicoClaw.

## IMPORTANT — T5 (memory) result: FAIL 0/5
NanoBot consolidates long-term memory **asynchronously** via a background "dream"
process (`agents.defaults.dream.intervalH = 2` hours). The store call acknowledges
("will be automatically saved to long-term memory") but does **not** write to
`MEMORY.md` synchronously. With the session wiped before recall (our protocol, so
recall must hit the memory store), NanoBot cannot recall ZX-9 → fails all 5 trials.
This is a genuine capability result, not a harness bug: ZeroClaw and PicoClaw persist
to a memory file immediately and recall fine; NanoBot's persistence is deferred.

## Scripts
- `scripts/bench_nanobot.sh <task1..task4>`
- `scripts/bench_nanobot_mem.sh` (task5)
Identical task prompts/checks to `bench.sh`; only AGENT, run command, paths, and the
session-clear step differ.
