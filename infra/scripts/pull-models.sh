#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
MODEL="${1:-qwen2.5:3b}"
echo "Pulling model: $MODEL"
docker compose exec ollama ollama pull "$MODEL"
docker compose exec ollama ollama list
