# PicoClaw — install notes, version, quirks (benchmark agent #2)

## Identity
- **Framework:** PicoClaw (Go), https://github.com/sipeed/picoclaw
- **Version:** 0.2.9 (git 2992eccb), build 2026-05-29, go 1.25.10
- **Architecture under test:** aarch64 (64-bit Raspberry Pi OS, Debian 13 trixie)

## Install (system-wide via official .deb)
```bash
cd /tmp
wget -O picoclaw_aarch64.deb \
  https://github.com/sipeed/picoclaw/releases/download/v0.2.9/picoclaw_aarch64.deb
sudo apt-get install -y ./picoclaw_aarch64.deb
```
Binaries: `/usr/bin/picoclaw` (CLI) and `/usr/bin/picoclaw-launcher` (web UI).

## Config / home (isolated, separate from zeroclaw)
- Real config + workspace live in **`~/picoclaw`** (via `PICOCLAW_HOME`).
- `~/.picoclaw` is a **symlink → `~/picoclaw`** so the default path also resolves
  there (works without the env var, in cron/systemd, etc.).
- Config file: `~/picoclaw/config.json` (scaffold via `picoclaw onboard`).
- Workspace: `~/picoclaw/workspace` (`restrict_to_workspace = true` — created files
  land here regardless of shell cwd).

## Cloud model (held constant with zeroclaw — fairness)
- Provider: **OpenRouter**, model **`google/gemini-3.1-pro-preview`** (same key as
  zeroclaw, copied from `~/.zeroclaw/config.toml`).
- **Quirk:** the key goes in a model_list entry under **`api_keys`** (array), NOT
  `api_key` — the schema rejects `api_key` ("unknown field model_list[0].api_key").
  Active model selected via `agents.defaults.provider` + `agents.defaults.model_name`.

## Non-interactive run command
```bash
picoclaw --no-color agent -m "<prompt>"     # -s/--session defaults to "cli:default"
```

## Out-of-the-box behavior (findings)
- **Writes files freely** — no approval prompt, no refusal (contrast: zeroclaw was
  secure-by-default and needed `autonomy = "full"`). PicoClaw needed no loosening.
- **Single process** — `picoclaw agent -m` does everything in one process (no forked
  gateway/daemon), so `/usr/bin/time %M` is a valid, comparable memory measurement.
  Idle: no background daemon running.
- **Memory footprint** ~31 MB on T1 (vs zeroclaw's flat ~20 MB).

## IMPORTANT methodology quirk — session persistence
PicoClaw **persists conversation history across separate `agent -m` calls** by
default (`workspace/sessions/*.jsonl`); a fresh call recalls the previous prompt.
ZeroClaw does NOT (`load_session_context = false`), so its trials were independent.

To keep the comparison fair and trials independent, the PicoClaw bench scripts
**clear `workspace/sessions/*.jsonl` before each call**:
- T1–T4: cleared before each trial (independence).
- T5: cleared before BOTH store and recall, so recall must come from the memory
  store (`workspace/memory/MEMORY.md`), not conversation history — verified: recall
  returns ZX-9 with the session wiped. Memory is reset to pristine once before the
  T5 suite (matches zeroclaw: no per-trial memory reset).

## Scripts
- `scripts/bench_picoclaw.sh <task1..task4>`
- `scripts/bench_picoclaw_mem.sh` (task5)
Identical task prompts/checks to `bench.sh`; only AGENT, run command, WORKSPACE,
and the session-clear step differ.
