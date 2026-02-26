# Ralph App Builder Demo

## What the Ralph Loop is

The Ralph Wiggum Loop is an autonomous engineering pattern where an LLM repeatedly edits a codebase, but never decides when the work is done. Completion is determined only by external verification.

Core rule:

- Confidence is not completion.
- Verification is completion.

This repository demonstrates that pattern with a Bash-controlled loop that asks Codex to build a web app from `SPEC.md` until `verify.sh` passes.

## Architecture (Text Diagram)

`SPEC.md` defines target behavior -> `ralph.sh` runs loop iterations -> each iteration runs `verify.sh` -> failures are captured and fed into a fresh Codex invocation -> Codex edits files -> loop repeats.

Verification path inside `verify.sh`:

1. Start app (if present) and run integration tests in `tests/test_api.py`
2. Build Docker image
3. Run container
4. Probe `/health`
5. Exit `0` only if every check succeeds

## Why verification controls completion

The loop does not trust model self-assessment. `verify.sh` is the only authority. If any step fails, the iteration fails, output is captured, and the next iteration uses that failure as input.

## Demo Steps (Exact Commands)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip pytest requests

# Start autonomous build loop
./ralph.sh

# Re-run authority check manually
./verify.sh
```

## Expected Iteration Behavior

- Iteration 1 starts with no application code and fails verification.
- Failure output is appended to `progress.log`.
- A fresh Codex run receives:
  - `SPEC.md` constraints
  - current repository context
  - previous failure output
- Codex creates/edits files (for example `app/`, `requirements.txt`, `Dockerfile`) and the loop retries.
- Loop stops immediately when `verify.sh` exits `0`, or fails after 12 iterations.

## Why this demonstrates autonomous software construction

The repository begins without an app. The app is produced by repeated machine-driven edits under a hard external test harness. Bash orchestrates control flow, state is file-based, and each AI attempt is disposable.
