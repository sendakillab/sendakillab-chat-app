#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example"; fi
docker compose up -d --build
printf '\nSendakilLab started.\nAPI docs: http://localhost:8000/docs\nHealth:   http://localhost:8000/health\nOllama:   http://localhost:11434\n'
