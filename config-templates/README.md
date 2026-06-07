# Pointing each agent at the language model

All agents were benchmarked against the **same** OpenAI-compatible endpoint
(OpenRouter for the cloud runs; a local Ollama server for the offline runs), holding
the model constant for fairness. No API keys are stored in this repo — set your own.

Replace `YOUR_API_KEY` below. Cloud model used: `google/gemini-3.1-pro-preview` via
`https://openrouter.ai/api/v1`. Offline used `qwen2.5:1.5b` / `smollm2:360m` via
`http://localhost:11434/v1` (Ollama).

### ZeroClaw — `~/.zeroclaw/config.toml`
```toml
default_provider = "openrouter"
[providers.models.openrouter]
api_key = "YOUR_API_KEY"
model = "google/gemini-3.1-pro-preview"

[autonomy]
level = "full"   # required so it writes files in non-interactive mode

# offline (Ollama):
[providers.models.ollama]
model = "qwen2.5:1.5b"
api_url = "http://localhost:11434"
```

### PicoClaw — `~/picoclaw/config.json` (model_list entry)
```json
{ "model_name": "openrouter-gemini-3.1-pro", "provider": "openrouter",
  "model": "google/gemini-3.1-pro-preview",
  "api_base": "https://openrouter.ai/api/v1", "api_keys": ["YOUR_API_KEY"] }
```
Note: the key field is `api_keys` (array), **not** `api_key`. Select via
`agents.defaults.provider` + `agents.defaults.model_name`.

### NanoBot — `~/.nanobot/config.json`
```json
{ "providers": { "openrouter": { "apiKey": "YOUR_API_KEY" } },
  "agents": { "defaults": { "provider": "openrouter",
                            "model": "google/gemini-3.1-pro-preview" } } }
```
For an OpenAI-compatible local endpoint, use the `openai` provider with `apiBase`
set to `http://localhost:11434/v1` and `apiType: "chat_completions"`.

### smolagents — environment variables (see `scripts/smol_runner.py`)
```bash
export OPENROUTER_API_KEY="YOUR_API_KEY"
export SMOL_MODEL="google/gemini-3.1-pro-preview"
export SMOL_API_BASE="https://openrouter.ai/api/v1"   # or http://localhost:11434/v1 for Ollama
export SMOL_WS="$HOME/smolagents-work"
```
