#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

IMAGE_TAG="ralph-app-builder:manual-check"
CONTAINER_NAME="ralph-app-builder-manual"

cleanup() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker build -t "$IMAGE_TAG" .
docker run -d --name "$CONTAINER_NAME" -p 8000:8000 "$IMAGE_TAG" >/dev/null

for _ in $(seq 1 45); do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

curl -fsS http://127.0.0.1:8000/health
