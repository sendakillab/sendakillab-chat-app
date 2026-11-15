# Phase 01 API Contract

Base path: `/api/v1`

## GET /models
Returns the models known by Ollama.

## POST /chat
Request:

```json
{
  "model": "qwen2.5:3b",
  "message": "Hello",
  "temperature": 0.7
}
```

Phase 01 starter response:

```json
{
  "model": "qwen2.5:3b",
  "message": {
    "role": "assistant",
    "content": "..."
  },
  "done": true
}
```

Streaming and persistence are intentionally the next development step rather than hidden in the starter skeleton.
