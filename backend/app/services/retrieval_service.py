from typing import List, Dict, Optional
from app.services.embedding_service import EmbeddingService
from app.services.vector_store_service import VectorStoreService
from app.core.config import settings

class RetrievalService:
    @classmethod
    async def search(
        cls, 
        query: str, 
        top_k: int = settings.DEFAULT_TOP_K,
        threshold: float = settings.DEFAULT_RELEVANCE_THRESHOLD
    ) -> Dict:
        """
        Embeds the query and performs a similarity search in the vector store.
        Filters results by a distance threshold.
        """
        # 1. Embed query
        # EmbeddingService.generate_embeddings expects a list of DocumentChunks or texts.
        # Let's check its implementation.
        
        model = EmbeddingService.get_model()
        query_embedding = model.encode([query], show_progress_bar=False)[0].tolist()

        # 2. Query Vector Store
        raw_results = await VectorStoreService.query(query_embedding, top_k=top_k)

        # 3. Process and filter results
        # Results are formatted as lists of lists for batch query compatibility.
        # We only have one query embedding.
        
        ids = raw_results.get("ids", [[]])[0]
        documents = raw_results.get("documents", [[]])[0]
        metadatas = raw_results.get("metadatas", [[]])[0]
        distances = raw_results.get("distances", [[]])[0]

        filtered_results = []
        for i in range(len(ids)):
            distance = distances[i]
            
            # pgvector cosine distance: lower value = higher similarity.
            if distance <= threshold:
                metadata = metadatas[i]
                filtered_results.append({
                    "text": documents[i],
                    "document_id": metadata.get("document_id"),
                    "document_name": metadata.get("document_name"),
                    "page_number": metadata.get("page_number") if metadata.get("page_number") != -1 else None,
                    "chunk_index": metadata.get("chunk_index"),
                    "distance": round(distance, 4)
                })

        return {
            "query": query,
            "results": filtered_results
        }
