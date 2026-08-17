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
    async def generate_embeddings(cls, chunks: List[DocumentChunk]) -> List[Dict]:
        """
        Generates embeddings for a list of DocumentChunk objects in batch.
        Returns a list of dicts with chunk_id and embedding.
        """
        if not chunks:
            return []

        model = cls.get_model()
        texts = [chunk.text for chunk in chunks]
        
        # Batch inference
        embeddings = model.encode(texts, show_progress_bar=False)
        
        result = []
        for i, chunk in enumerate(chunks):
            result.append({
                "chunk_id": chunk.chunk_id,
                "embedding": embeddings[i].tolist()
            })
            
        return result
