import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from app.core.database import engine, Base
from app.models import User, Document, Conversation, ConversationDocument, Message, MessageSource, WebSearchLog
from app.routes.auth import router as auth_router
from app.routes.providers import router as providers_router
from app.routes.documents import router as documents_router
from app.routes.retrieval import router as retrieval_router
from app.routes.conversations import router as conversations_router
from app.services.embedding_service import EmbeddingService

def run_auto_migrations():
    """Safely creates tables and adds new columns to existing PostgreSQL/SQLite tables on startup."""
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as e:
        print(f"Warning: Base.metadata.create_all: {e}")

    migration_statements = [
        "ALTER TABLE documents ADD COLUMN IF NOT EXISTS source_type VARCHAR DEFAULT 'upload';",
        "ALTER TABLE documents ADD COLUMN IF NOT EXISTS url VARCHAR;",
        "ALTER TABLE documents ADD COLUMN IF NOT EXISTS query_that_triggered_it TEXT;",
        "ALTER TABLE documents ADD COLUMN IF NOT EXISTS content_hash VARCHAR;",
        "ALTER TABLE documents ALTER COLUMN storage_path DROP NOT NULL;",
        "ALTER TABLE message_sources ADD COLUMN IF NOT EXISTS source_type VARCHAR DEFAULT 'document';",
        "ALTER TABLE message_sources ADD COLUMN IF NOT EXISTS url VARCHAR;",
        "ALTER TABLE message_sources ADD COLUMN IF NOT EXISTS title VARCHAR;",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR DEFAULT 'email';",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR;",
    ]

    with engine.connect() as conn:
        for stmt in migration_statements:
            try:
                conn.execute(text(stmt))
                conn.commit()
            except Exception:
                pass

# Run automatic migration on module import
run_auto_migrations()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure migrations are applied and pre-warm embedding model
    run_auto_migrations()
    asyncio.create_task(asyncio.to_thread(EmbeddingService.get_model))
    yield

app = FastAPI(
    title="RAG Agent & Multi-Tool API",
    description="Backend API for AI Document Assistant, Authentication, Vector Retrieval & Agent Pipelines",
    version="2.0.0",
    lifespan=lifespan,
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router)
app.include_router(providers_router)
app.include_router(documents_router)
app.include_router(retrieval_router)
app.include_router(conversations_router)

@app.api_route("/", methods=["GET", "HEAD"])
def root():
    return {
        "status": "online",
        "message": "RAG Agent & Multi-Tool Backend is running",
        "version": "2.0.0"
    }

@app.api_route("/health", methods=["GET", "HEAD"])
def health():
    return {
        "status": "healthy",
        "database": "connected"
    }