import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import engine, Base
from app.models import User, Document, Conversation, ConversationDocument, Message, MessageSource
from app.routes.auth import router as auth_router
from app.routes.providers import router as providers_router
from app.routes.documents import router as documents_router
from app.routes.retrieval import router as retrieval_router
from app.routes.conversations import router as conversations_router
from app.services.embedding_service import EmbeddingService

# Auto-create all tables in the database if they do not exist
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print(f"Warning: Automatic table creation encountered: {e}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Pre-warm embedding model in background thread so first query has 0 latency
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