import asyncio
import asyncio
from typing import List, Dict
from sentence_transformers import SentenceTransformer
from app.core.config import settings
from app.services.chunking_service import DocumentChunk

class EmbeddingService:
    _model = None

    @classmethod
    def get_model(cls):
        if cls._model is None:
            # Load model once and reuse it
            cls._model = SentenceTransformer(settings.EMBEDDING_MODEL_NAME)
        return cls._model

    @classmethod
    async def encode_query(cls, query: str) -> List[float]:
        """
        Embeds a single search query on a threadpool without blocking the async event loop.
        """
        def _encode():
            model = cls.get_model()
            return model.encode([query], show_progress_bar=False)[0].tolist()

        return await asyncio.to_thread(_encode)

    @classmethod
    async def generate_embeddings(cls, chunks: List[DocumentChunk]) -> List[Dict]:
        """
        Generates embeddings for a list of DocumentChunk objects in batch.
        Returns a list of dicts with chunk_id and embedding.
        """
        if not chunks:
            return []

        def run_encoding():
            model = cls.get_model()
            texts = [chunk.text for chunk in chunks]
            return model.encode(texts, show_progress_bar=False)

        # Run blocking encoding in a separate thread
        embeddings = await asyncio.to_thread(run_encoding)
        
        result = []
        for i, chunk in enumerate(chunks):
            result.append({
                "chunk_id": chunk.chunk_id,
                "embedding": embeddings[i].tolist()
            })
            
        return result
