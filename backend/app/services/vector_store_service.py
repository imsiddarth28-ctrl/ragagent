try:
    import vecs
except ImportError:
    vecs = None
from typing import List, Dict, Optional
from app.core.config import settings
from app.services.chunking_service import DocumentChunk

class VectorStoreService:
    _client = None
    _collection = None

    @classmethod
    def get_client(cls):
        if cls._client is None:
            # Connect to Supabase/PostgreSQL using the same DATABASE_URL
            # pgvector must be enabled on the DB: CREATE EXTENSION IF NOT EXISTS vector;
            cls._client = vecs.create_client(settings.DATABASE_URL)
        return cls._client

    @classmethod
    def get_collection(cls):
        if cls._collection is None:
            client = cls.get_client()
            # In pgvector, we need to specify the dimension. 
            # all-MiniLM-L6-v2 uses 384 dimensions.
            cls._collection = client.get_or_create_collection(
                name=settings.COLLECTION_NAME, 
                dimension=384
            )
        return cls._collection

    @classmethod
    async def upsert_chunks(cls, chunks: List[DocumentChunk], embeddings: List[List[float]]):
        """
        Stores chunks and their embeddings in Supabase pgvector.
        """
        if not chunks:
            return

        collection = cls.get_collection()
        
        # vecs expects a list of (id, vector, metadata)
        records = []
        for i, chunk in enumerate(chunks):
            records.append((
                chunk.chunk_id,
                embeddings[i],
                {
                    "document_id": chunk.document_id,
                    "document_name": chunk.document_name,
                    "page_number": chunk.page_number if chunk.page_number is not None else -1,
                    "chunk_index": chunk.chunk_index,
                    "text": chunk.text # Storing text in metadata for easy retrieval
                }
            ))

        collection.upsert(records=records)

    @classmethod
    async def delete_document_chunks(cls, document_id: str):
        """
        Removes all chunks associated with a specific document_id.
        """
        collection = cls.get_collection()
        # pgvector (vecs) supports filtering by metadata during deletion
        collection.delete(filters={"document_id": {"$eq": document_id}})

    @classmethod
    async def query(cls, query_embedding: List[float], top_k: int = 4) -> Dict:
        """
        Performs a similarity search in Supabase.
        """
        collection = cls.get_collection()
        
        # Performs cosine distance search by default
        results = collection.query(
            data=query_embedding,
            limit=top_k,
            include_value=True,
            include_metadata=True
        )

        # Format to match our previous ChromaDB output for the RetrievalService
        formatted_results = {
            "ids": [[]],
            "documents": [[]],
            "metadatas": [[]],
            "distances": [[]]
        }

        for chunk_id, distance, metadata in results:
            formatted_results["ids"][0].append(chunk_id)
            formatted_results["documents"][0].append(metadata.get("text", ""))
            formatted_results["metadatas"][0].append(metadata)
            formatted_results["distances"][0].append(distance)

        return formatted_results
