# Locked Phase 01 decisions

- Local-first, cloud-ready architecture.
- Flutter for web/desktop/mobile UI.
- FastAPI is the only application-facing gateway to models.
- Ollama provides local model serving.
- PostgreSQL is the relational source of truth.
- Redis is optional in Phase 01.
- Docker Compose is the local orchestration standard.
- Configuration is externalized through environment variables.
- Local file storage must be abstracted so it can move to S3 later.
- AWS Terraform will be added when cloud migration begins.
