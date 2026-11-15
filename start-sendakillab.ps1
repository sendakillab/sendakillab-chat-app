$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\MyLab\sendakillab\projects\chat-app"
$FlutterRoot = Join-Path $ProjectRoot "apps\flutter_client"
$LogDir = Join-Path $ProjectRoot "logs"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Test-Port {
    param([int]$Port)
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Wait-Http {
    param(
        [string]$Url,
        [int]$Retries = 30,
        [int]$DelaySeconds = 2
    )
    for ($i = 1; $i -le $Retries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                return $true
            }
        } catch {
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    return $false
}

Write-Host ""
Write-Host "=== Starting SendakilLab Chat App ===" -ForegroundColor Cyan

if (-not (Test-Path $ProjectRoot)) {
    throw "Project folder not found: $ProjectRoot"
}

Write-Host "Checking Docker..." -ForegroundColor Yellow
$dockerReady = $false

try {
    docker info *> $null
    $dockerReady = $true
} catch {}

if (-not $dockerReady) {
    $dockerCandidates = @(
        "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop.exe",
        "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    )

    $dockerExe = $dockerCandidates |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1

    if (-not $dockerExe) {
        throw "Docker Desktop executable was not found."
    }

    Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
    Start-Process $dockerExe

    for ($i = 1; $i -le 60; $i++) {
        Start-Sleep -Seconds 2
        try {
            docker info *> $null
            $dockerReady = $true
            break
        } catch {}
    }

    if (-not $dockerReady) {
        throw "Docker did not become ready."
    }
}

Write-Host "Docker is ready." -ForegroundColor Green

Set-Location $ProjectRoot
Write-Host "Starting Docker Compose services..." -ForegroundColor Yellow
docker compose up -d

if ($LASTEXITCODE -ne 0) {
    throw "docker compose up -d failed."
}

Write-Host ""
docker compose ps
Write-Host ""

Write-Host "Waiting for FastAPI..." -ForegroundColor Yellow
if (Wait-Http -Url "http://localhost:8000/health" -Retries 40 -DelaySeconds 2) {
    Write-Host "FastAPI is healthy." -ForegroundColor Green
} else {
    Write-Warning "FastAPI health check failed. Run: docker compose logs api"
}

Write-Host "Checking Docker Ollama..." -ForegroundColor Yellow
try {
    $models = docker exec sendakillab-ollama ollama list 2>$null
    Write-Host $models
} catch {
    Write-Warning "Could not query sendakillab-ollama."
}

if (-not (Test-Port -Port 8080)) {
    Write-Host "Starting Flutter Web..." -ForegroundColor Yellow

    $flutterLog = Join-Path $LogDir "flutter-web.log"
    $command = @"
Set-Location '$FlutterRoot'
flutter run -d web-server --web-port 8080 --dart-define=API_BASE_URL=http://localhost:8000 *> '$flutterLog'
"@

    Start-Process powershell.exe `
        -WindowStyle Minimized `
        -ArgumentList @(
            "-NoLogo",
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-Command", $command
        )

    for ($i = 1; $i -le 30; $i++) {
        Start-Sleep -Seconds 2
        if (Test-Port -Port 8080) {
            break
        }
    }
}

if (Test-Port -Port 8080) {
    Write-Host "Flutter Web is running." -ForegroundColor Green
    Start-Process "http://localhost:8080"
} else {
    Write-Warning "Flutter Web did not start. Check: $LogDir\flutter-web.log"
}

Write-Host ""
Write-Host "=== SendakilLab Chat App Status ===" -ForegroundColor Cyan
Write-Host "UI       : http://localhost:8080"
Write-Host "FastAPI  : http://localhost:8000"
Write-Host "Swagger  : http://localhost:8000/docs"
Write-Host "Ollama   : Docker container sendakillab-ollama"
Write-Host "Project  : $ProjectRoot"
Write-Host ""
