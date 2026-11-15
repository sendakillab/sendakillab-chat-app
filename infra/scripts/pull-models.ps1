param([string]$Model = "qwen2.5:3b")
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "../..")
Write-Host "Pulling model: $Model"
docker compose exec ollama ollama pull $Model
docker compose exec ollama ollama list
