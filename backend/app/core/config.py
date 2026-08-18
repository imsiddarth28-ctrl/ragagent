import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = "RAG Agent"
    
    # RAG Configuration
    CHUNK_SIZE: int = 1000
    CHUNK_OVERLAP: int = 200
    
    # Embedding Configuration
    EMBEDDING_MODEL_NAME: str = "all-MiniLM-L6-v2"
    
    # Vector Database Configuration
    COLLECTION_NAME: str = "document_chunks"
    
    # Vector DB persistence (Only for local ChromaDB fallback)
    VECTOR_DB_DIR: str = os.getenv("VECTOR_DB_DIR", "vector_db")
    
    # Retrieval Configuration
    DEFAULT_TOP_K: int = 4
    DEFAULT_RELEVANCE_THRESHOLD: float = 1.2

    # Database Configuration
    DATABASE_URL: str = os.getenv("DATABASE_URL", "")

    # Supabase Configuration (for Storage)
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")
    SUPABASE_BUCKET: str = "documents"

    # RAG System Prompt
    RAG_SYSTEM_PROMPT: str = """
    You are a helpful AI Assistant that answers questions based ONLY on the provided context.
    
    Context:
    {context}
    
    Instructions:
    1. Use the provided context to answer the user's question.
    2. If the answer is not in the context, say "I don't have enough information in your documents to answer this."
    3. Be concise and professional.
    4. Cite your sources if possible (e.g., "According to document.pdf...").
    """

settings = Settings()
