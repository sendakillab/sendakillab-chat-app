#!/usr/bin/env bash
set -euo pipefail
curl -fsS http://localhost:8000/health
printf '\n'
curl -fsS http://localhost:8000/api/v1/models
printf '\n'
