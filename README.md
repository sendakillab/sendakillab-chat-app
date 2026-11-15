# SendakilLab Chat App

SendakilLab Phase A local MVP.

## Current architecture

```text
Browser
  |
Flutter Web :8080
  |
FastAPI :8000
  |
Docker Compose network
  |-- PostgreSQL
  |-- Redis
  `-- Ollama
       `-- qwen2.5:3b
```

## Project location

```text
C:\MyLab\sendakillab\projects\chat-app
```

## Runtime data kept outside this Git repository

```text
C:\MyLab\ollama-data
C:\MyLab\docker-data
```

## Start

Double-click:

```text
start-sendakillab.cmd
```

Or:

```powershell
cd C:\MyLab\sendakillab\projects\chat-app
docker compose up -d
```

Then start Flutter Web if it is not already started by the script.

## Stop

Double-click:

```text
stop-sendakillab.cmd
```

The stop script does not delete Docker volumes.

## Useful URLs

- UI: http://localhost:8080
- FastAPI health: http://localhost:8000/health
- Swagger: http://localhost:8000/docs
- Models API: http://localhost:8000/api/v1/models

## Configuration

Copy `.env.example` to `.env` and provide local secret values.

Never commit `.env`.

## Phase A status

- Flutter Web UI
- FastAPI backend
- PostgreSQL chat persistence
- Redis service
- Docker-hosted Ollama
- qwen2.5:3b
- Start/stop scripts
- Docker Compose runtime

## Next

Phase B: AWS MVP deployment.
