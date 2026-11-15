$ErrorActionPreference = "Continue"

$ProjectRoot = "C:\MyLab\sendakillab\projects\chat-app"
$FlutterPort = 8080

Write-Host ""
Write-Host "=== Stopping SendakilLab Chat App ===" -ForegroundColor Cyan

Write-Host "Checking Flutter Web on port $FlutterPort..." -ForegroundColor Yellow

$connections = Get-NetTCPConnection `
    -LocalPort $FlutterPort `
    -State Listen `
    -ErrorAction SilentlyContinue

if ($connections) {
    $pids = $connections |
        Select-Object -ExpandProperty OwningProcess -Unique

    foreach ($pidValue in $pids) {
        try {
            $process = Get-Process -Id $pidValue -ErrorAction Stop
            Write-Host "Stopping $($process.ProcessName) (PID $pidValue)..." -ForegroundColor Yellow
            Stop-Process -Id $pidValue -Force -ErrorAction Stop
            Write-Host "Flutter/Web process stopped." -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not stop PID $pidValue : $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "No service is listening on port $FlutterPort." -ForegroundColor DarkGray
}

if (Test-Path $ProjectRoot) {
    Set-Location $ProjectRoot

    Write-Host ""
    Write-Host "Stopping Docker Compose services..." -ForegroundColor Yellow

    docker compose stop

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker Compose services stopped." -ForegroundColor Green
    } else {
        Write-Warning "docker compose stop returned an error."
    }

    Write-Host ""
    docker compose ps
} else {
    Write-Warning "Project folder not found: $ProjectRoot"
}

Write-Host ""
Write-Host "=== SendakilLab Chat App stopped ===" -ForegroundColor Cyan
Write-Host "Flutter Web : stopped"
Write-Host "FastAPI     : stopped"
Write-Host "PostgreSQL  : stopped"
Write-Host "Redis       : stopped"
Write-Host "Ollama      : stopped"
Write-Host ""
Write-Host "Persistent volumes/data were NOT deleted." -ForegroundColor Green
Write-Host "Docker Desktop remains running." -ForegroundColor DarkGray
Write-Host ""
