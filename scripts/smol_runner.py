#!/usr/bin/env python3
"""Single-task runner for smolagents (a library, not a turnkey agent).
Usage: smol_runner.py "<prompt>"
Env: OPENROUTER_API_KEY, SMOL_MODEL, SMOL_WS (workspace dir).

smolagents ships NO file tools, so we provide minimal write/read/append tools so
file tasks are possible (documented harness adaptation). Uses CodeAgent — the
flagship default agent — over an OpenAI-compatible OpenRouter endpoint. Each
invocation is a fresh process => trials are independent, no cross-process memory.
"""
import os, sys
from smolagents import CodeAgent, OpenAIModel, tool

WS = os.environ.get("SMOL_WS", os.path.expanduser("~/smolagents-work"))
os.makedirs(WS, exist_ok=True)
os.chdir(WS)

@tool
def write_file(filename: str, content: str) -> str:
    """Create or overwrite a file with exact text content.

    Args:
        filename: name of the file to write (relative to the workspace).
        content: the exact text to write into the file.
    """
    with open(os.path.join(WS, filename), "w") as f:
        f.write(content)
    return f"wrote {filename}"

@tool
def read_file(filename: str) -> str:
    """Read and return the full text content of a file.

    Args:
        filename: name of the file to read (relative to the workspace).
    """
    with open(os.path.join(WS, filename)) as f:
        return f.read()

@tool
def append_file(filename: str, line: str) -> str:
    """Append a line of text to a file, creating it if it does not exist.

    Args:
        filename: name of the file to append to (relative to the workspace).
        line: the text to append; a trailing newline is added automatically.
    """
    with open(os.path.join(WS, filename), "a") as f:
        f.write(line + "\n")
    return f"appended to {filename}"

model = OpenAIModel(
    model_id=os.environ["SMOL_MODEL"],
    api_base=os.environ.get("SMOL_API_BASE", "https://openrouter.ai/api/v1"),
    api_key=os.environ["OPENROUTER_API_KEY"],
)
agent = CodeAgent(
    tools=[write_file, read_file, append_file],
    model=model,
    additional_authorized_imports=["os", "pathlib"],
)
result = agent.run(sys.argv[1])
print("FINAL_ANSWER:", result)
