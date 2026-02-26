#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

MAX_ITERATIONS=12
PROGRESS_LOG="$ROOT_DIR/progress.log"

touch "$PROGRESS_LOG"

run_codex_iteration() {
  local iteration="$1"
  local failure_log="$2"
  local prompt_file
  prompt_file="$(mktemp)"

  cat > "$prompt_file" <<PROMPT
You are working in this repository. Follow SPEC.md exactly.

Rules:
- This is not a chatbot task. Edit files directly.
- Use the verification harness as the source of truth.
- Address the failure output from the previous iteration.
- You may create or modify any required files, including app/, Dockerfile, requirements.txt, and code/tests needed by SPEC.md.
- Continue until the repository moves toward verify.sh passing.

Current iteration: ${iteration}

Failure output from ./verify.sh:
$(cat "$failure_log")
PROMPT

  {
    echo ""
    echo "===== ITERATION ${iteration}: CODEX START $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
    codex exec --ephemeral --dangerously-bypass-approvals-and-sandbox -C "$ROOT_DIR" - < "$prompt_file"
    echo "===== ITERATION ${iteration}: CODEX END $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
  } >> "$PROGRESS_LOG" 2>&1

  rm -f "$prompt_file"
}

for ((iteration=1; iteration<=MAX_ITERATIONS; iteration++)); do
  failure_log="$(mktemp)"

  {
    echo ""
    echo "===== ITERATION ${iteration}: VERIFY START $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
  } >> "$PROGRESS_LOG"

  if ./verify.sh > "$failure_log" 2>&1; then
    {
      cat "$failure_log"
      echo "===== ITERATION ${iteration}: VERIFY SUCCESS ====="
      echo "Ralph loop completed in ${iteration} iteration(s)."
    } >> "$PROGRESS_LOG"
    rm -f "$failure_log"
    exit 0
  fi

  {
    cat "$failure_log"
    echo "===== ITERATION ${iteration}: VERIFY FAILED ====="
  } >> "$PROGRESS_LOG"

  run_codex_iteration "$iteration" "$failure_log"
  rm -f "$failure_log"
done

echo "Ralph loop reached max iterations (${MAX_ITERATIONS}) without success." | tee -a "$PROGRESS_LOG"
exit 1
