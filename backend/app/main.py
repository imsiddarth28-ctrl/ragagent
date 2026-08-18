from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.providers import router as providers_router
from app.routes.documents import router as documents_router
from app.routes.retrieval import router as retrieval_router
from app.routes.conversations import router as conversations_router


app = FastAPI(
    title="RAG Agent API",
    description="Backend for the AI Document Assistant",
    version="1.0.0",
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(providers_router)
app.include_router(documents_router)
app.include_router(retrieval_router)
app.include_router(conversations_router)


@app.get("/")
def root():
    return {
        "message": "RAG Agent Backend is running"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }