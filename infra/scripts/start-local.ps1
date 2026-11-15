$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "../..")
if (-not (Test-Path ".env")) { Copy-Item ".env.example" ".env"; Write-Host "Created .env from .env.example" }
docker compose up -d --build
Write-Host ""
Write-Host "SendakilLab started."
Write-Host "API docs: http://localhost:8000/docs"
Write-Host "Health:   http://localhost:8000/health"
Write-Host "Ollama:   http://localhost:11434"
