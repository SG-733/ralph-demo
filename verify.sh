#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

IMAGE_TAG="ralph-app-builder:verify"
CONTAINER_NAME="ralph-app-builder-verify"
APP_PID=""

cleanup() {
  if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_for_health() {
  local url="$1"
  local attempts="${2:-30}"
  local sleep_seconds="${3:-1}"
  local i
  for ((i=1; i<=attempts; i++)); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$sleep_seconds"
  done
  return 1
}

echo "[verify] step 1/5: start local app and run pytest"

if [[ ! -f "app/main.py" ]]; then
  echo "[verify] missing app/main.py"
  exit 1
fi

python3 -m uvicorn app.main:app --host 127.0.0.1 --port 8000 >/tmp/ralph-local-app.log 2>&1 &
APP_PID="$!"

if ! wait_for_health "http://127.0.0.1:8000/health" 45 1; then
  echo "[verify] local service did not start"
  echo "[verify] local app logs:"
  cat /tmp/ralph-local-app.log || true
  exit 1
fi

pytest -q tests/test_api.py

kill "$APP_PID" 2>/dev/null || true
wait "$APP_PID" 2>/dev/null || true
APP_PID=""

echo "[verify] step 2/5: build docker image"
docker build -t "$IMAGE_TAG" .

echo "[verify] step 3/5: run container"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER_NAME" -p 8000:8000 "$IMAGE_TAG" >/tmp/ralph-container-id.log

echo "[verify] step 4/5: wait for container startup"
if ! wait_for_health "http://127.0.0.1:8000/health" 45 1; then
  echo "[verify] container service did not start"
  docker logs "$CONTAINER_NAME" || true
  exit 1
fi

echo "[verify] step 5/5: curl /health"
HEALTH_PAYLOAD="$(curl -fsS http://127.0.0.1:8000/health)"
if [[ "$HEALTH_PAYLOAD" != '{"status":"ok"}' ]]; then
  echo "[verify] unexpected /health payload: $HEALTH_PAYLOAD"
  exit 1
fi

echo "[verify] success"
exit 0
