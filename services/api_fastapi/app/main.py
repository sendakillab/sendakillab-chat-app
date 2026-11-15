import os
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, text

APP_NAME = os.getenv("APP_NAME", "SendakilLab")
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://host.docker.internal:11434")
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "qwen2.5:3b")
DATABASE_URL = os.getenv("DATABASE_URL", "")

app = FastAPI(title=f"{APP_NAME} API", version="0.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True) if DATABASE_URL else None


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def require_db():
    if engine is None:
        raise HTTPException(
            status_code=503,
            detail="DATABASE_URL is not configured.",
        )
    return engine


def init_database() -> None:
    if engine is None:
        return

    with engine.begin() as conn:
        conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS conversations (
                    id VARCHAR(36) PRIMARY KEY,
                    title VARCHAR(200) NOT NULL,
                    model_name VARCHAR(200),
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """
            )
        )
        conn.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS messages (
                    id VARCHAR(36) PRIMARY KEY,
                    conversation_id VARCHAR(36) NOT NULL
                        REFERENCES conversations(id) ON DELETE CASCADE,
                    role VARCHAR(20) NOT NULL,
                    content TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                )
                """
            )
        )
        conn.execute(
            text(
                """
                CREATE INDEX IF NOT EXISTS ix_messages_conversation_id_created_at
                ON messages(conversation_id, created_at)
                """
            )
        )
        conn.execute(
            text(
                """
                CREATE INDEX IF NOT EXISTS ix_conversations_updated_at
                ON conversations(updated_at DESC)
                """
            )
        )


@app.on_event("startup")
def startup() -> None:
    init_database()


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)
    model: str | None = None
    temperature: float = 0.7
    conversation_id: str | None = None


class ConversationCreate(BaseModel):
    title: str | None = None
    model_name: str | None = None


def make_title(message: str) -> str:
    compact = " ".join(message.strip().split())
    if not compact:
        return "New conversation"
    return compact[:57] + "..." if len(compact) > 60 else compact


def ensure_conversation(conversation_id: str) -> dict[str, Any]:
    db = require_db()
    with db.begin() as conn:
        row = conn.execute(
            text(
                """
                SELECT id, title, model_name, created_at, updated_at
                FROM conversations
                WHERE id = :id
                """
            ),
            {"id": conversation_id},
        ).mappings().first()

    if row is None:
        raise HTTPException(status_code=404, detail="Conversation not found.")
    return dict(row)


def create_conversation(title: str, model_name: str | None) -> str:
    db = require_db()
    conversation_id = str(uuid4())
    now = utcnow()

    with db.begin() as conn:
        conn.execute(
            text(
                """
                INSERT INTO conversations (
                    id, title, model_name, created_at, updated_at
                )
                VALUES (
                    :id, :title, :model_name, :created_at, :updated_at
                )
                """
            ),
            {
                "id": conversation_id,
                "title": title,
                "model_name": model_name,
                "created_at": now,
                "updated_at": now,
            },
        )

    return conversation_id


def add_message(conversation_id: str, role: str, content: str) -> None:
    db = require_db()
    now = utcnow()

    with db.begin() as conn:
        conn.execute(
            text(
                """
                INSERT INTO messages (
                    id, conversation_id, role, content, created_at
                )
                VALUES (
                    :id, :conversation_id, :role, :content, :created_at
                )
                """
            ),
            {
                "id": str(uuid4()),
                "conversation_id": conversation_id,
                "role": role,
                "content": content,
                "created_at": now,
            },
        )
        conn.execute(
            text(
                """
                UPDATE conversations
                SET updated_at = :updated_at
                WHERE id = :id
                """
            ),
            {"updated_at": now, "id": conversation_id},
        )


@app.get("/health")
async def health() -> dict[str, Any]:
    ollama_ok = False
    ollama_error = None
    database_ok = False
    database_error = None

    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/tags")
            ollama_ok = response.is_success
    except Exception as exc:
        ollama_error = str(exc)

    if engine is not None:
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            database_ok = True
        except Exception as exc:
            database_error = str(exc)

    return {
        "status": "ok",
        "app": APP_NAME,
        "database_configured": bool(DATABASE_URL),
        "database": {
            "reachable": database_ok,
            "error": database_error,
        },
        "ollama": {
            "reachable": ollama_ok,
            "error": ollama_error,
        },
    }


@app.get("/api/v1/models")
async def models() -> dict[str, Any]:
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/tags")
            response.raise_for_status()
            return response.json()
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Ollama unavailable: {exc}",
        ) from exc


@app.post("/api/v1/conversations")
async def new_conversation(request: ConversationCreate) -> dict[str, Any]:
    title = request.title or "New conversation"
    conversation_id = create_conversation(title, request.model_name)
    return {"id": conversation_id}


@app.get("/api/v1/conversations")
async def list_conversations() -> list[dict[str, Any]]:
    db = require_db()

    with db.begin() as conn:
        rows = conn.execute(
            text(
                """
                SELECT
                    c.id,
                    c.title,
                    c.model_name,
                    c.created_at,
                    c.updated_at,
                    COUNT(m.id) AS message_count
                FROM conversations c
                LEFT JOIN messages m
                    ON m.conversation_id = c.id
                GROUP BY
                    c.id,
                    c.title,
                    c.model_name,
                    c.created_at,
                    c.updated_at
                ORDER BY c.updated_at DESC
                """
            )
        ).mappings().all()

    return [
        {
            "id": row["id"],
            "title": row["title"],
            "model_name": row["model_name"],
            "created_at": row["created_at"].isoformat(),
            "updated_at": row["updated_at"].isoformat(),
            "message_count": int(row["message_count"]),
        }
        for row in rows
    ]


@app.get("/api/v1/conversations/{conversation_id}")
async def get_conversation(conversation_id: str) -> dict[str, Any]:
    conversation = ensure_conversation(conversation_id)
    db = require_db()

    with db.begin() as conn:
        rows = conn.execute(
            text(
                """
                SELECT id, role, content, created_at
                FROM messages
                WHERE conversation_id = :conversation_id
                ORDER BY created_at ASC
                """
            ),
            {"conversation_id": conversation_id},
        ).mappings().all()

    return {
        "id": conversation["id"],
        "title": conversation["title"],
        "model_name": conversation["model_name"],
        "created_at": conversation["created_at"].isoformat(),
        "updated_at": conversation["updated_at"].isoformat(),
        "messages": [
            {
                "id": row["id"],
                "role": row["role"],
                "content": row["content"],
                "created_at": row["created_at"].isoformat(),
            }
            for row in rows
        ],
    }


@app.delete("/api/v1/conversations/{conversation_id}")
async def delete_conversation(conversation_id: str) -> dict[str, Any]:
    db = require_db()

    with db.begin() as conn:
        result = conn.execute(
            text("DELETE FROM conversations WHERE id = :id"),
            {"id": conversation_id},
        )

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Conversation not found.")

    return {"deleted": True, "id": conversation_id}


@app.post("/api/v1/chat")
async def chat(request: ChatRequest) -> dict[str, Any]:
    selected_model = request.model or DEFAULT_MODEL

    if request.conversation_id:
        conversation = ensure_conversation(request.conversation_id)
        conversation_id = conversation["id"]

        db = require_db()
        with db.begin() as conn:
            conn.execute(
                text(
                    """
                    UPDATE conversations
                    SET model_name = :model_name,
                        updated_at = :updated_at
                    WHERE id = :id
                    """
                ),
                {
                    "model_name": selected_model,
                    "updated_at": utcnow(),
                    "id": conversation_id,
                },
            )
    else:
        conversation_id = create_conversation(
            make_title(request.message),
            selected_model,
        )

    add_message(conversation_id, "user", request.message)

    payload = {
        "model": selected_model,
        "messages": [
            {
                "role": "user",
                "content": request.message,
            }
        ],
        "stream": False,
        "options": {
            "temperature": request.temperature,
        },
    }

    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                f"{OLLAMA_BASE_URL}/api/chat",
                json=payload,
            )
            response.raise_for_status()
            body = response.json()

        message = body.get("message", {})
        assistant_content = (message.get("content") or "").strip()

        if not assistant_content:
            assistant_content = "The model returned an empty response."

        add_message(
            conversation_id,
            "assistant",
            assistant_content,
        )

        return {
            "conversation_id": conversation_id,
            "model": body.get("model", selected_model),
            "message": {
                "role": "assistant",
                "content": assistant_content,
            },
            "done": body.get("done", True),
        }

    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=502,
            detail=exc.response.text,
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Model runtime unavailable: {exc}",
        ) from exc
