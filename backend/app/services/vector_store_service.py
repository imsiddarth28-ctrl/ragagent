import os
import json
import numpy as np
from typing import List, Dict, Optional
from app.core.config import settings
from app.services.chunking_service import DocumentChunk

try:
    import vecs
except Exception:
    vecs = None

class VectorStoreService:
    _client = None
    _collection = None
    # Local in-memory/file fallback index for zero-cost operation
    _local_store: Dict[str, Dict] = {} # chunk_id -> {embedding, metadata, text}

    @classmethod
    def _is_pgvector_available(cls) -> bool:
        return bool(vecs and settings.DATABASE_URL and settings.DATABASE_URL.startswith("postgresql"))

    @classmethod
    def get_client(cls):
        if cls._client is None and cls._is_pgvector_available():
            try:
                cls._client = vecs.create_client(settings.DATABASE_URL)
            except Exception as e:
                print(f"⚠️ pgvector connection note: {e}")
                cls._client = None
        return cls._client

    @classmethod
    def get_collection(cls):
        if cls._collection is None:
            client = cls.get_client()
            if client:
                try:
                    cls._collection = client.get_or_create_collection(
                        name=settings.COLLECTION_NAME, 
                        dimension=384
                    )
                except Exception as e:
                    print(f"⚠️ pgvector collection note: {e}")
                    cls._collection = None
        return cls._collection

    @classmethod
    async def upsert_chunks(cls, chunks: List[DocumentChunk], embeddings: List[List[float]]):
        """
        Stores chunks and their embeddings in Supabase pgvector or local store.
        """
        if not chunks:
            return

        collection = cls.get_collection()
        if collection:
            try:
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
                            "text": chunk.text
                        }
                    ))
                collection.upsert(records=records)
                return
            except Exception as e:
                print(f"⚠️ pgvector upsert fallback: {e}")

        # Local vector index fallback
        for i, chunk in enumerate(chunks):
            cls._local_store[chunk.chunk_id] = {
                "chunk_id": chunk.chunk_id,
                "document_id": chunk.document_id,
                "document_name": chunk.document_name,
                "page_number": chunk.page_number if chunk.page_number is not None else -1,
                "chunk_index": chunk.chunk_index,
                "text": chunk.text,
                "embedding": np.array(embeddings[i], dtype=np.float32)
            }

    @classmethod
    async def delete_document_chunks(cls, document_id: str):
        """
        Removes all chunks associated with a specific document_id.
        """
        collection = cls.get_collection()
        if collection:
            try:
                collection.delete(filters={"document_id": {"$eq": document_id}})
            except Exception as e:
                print(f"⚠️ pgvector delete note: {e}")

        to_remove = [k for k, v in cls._local_store.items() if v.get("document_id") == document_id]
        for k in to_remove:
            cls._local_store.pop(k, None)

    @classmethod
    async def query(cls, query_embedding: List[float], top_k: int = 4, document_ids: Optional[List[str]] = None) -> Dict:
        """
        Performs a similarity search in Supabase pgvector or local vector store.
        """
        collection = cls.get_collection()
        if collection:
            try:
                filters = None
                if document_ids:
                    filters = {"document_id": {"$in": document_ids}}

                results = collection.query(
                    data=query_embedding,
                    limit=top_k,
                    filters=filters,
                    include_value=True,
                    include_metadata=True
                )

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
            except Exception as e:
                print(f"⚠️ pgvector query note, using local vector store: {e}")

        # Local Cosine Similarity query
        formatted_results = {
            "ids": [[]],
            "documents": [[]],
            "metadatas": [[]],
            "distances": [[]]
        }

        if not cls._local_store:
            return formatted_results

        q_vec = np.array(query_embedding, dtype=np.float32)
        q_norm = np.linalg.norm(q_vec)
        if q_norm == 0:
            return formatted_results

        candidates = []
        for chunk_id, item in cls._local_store.items():
            if document_ids and item.get("document_id") not in document_ids:
                continue
            emb = item["embedding"]
            emb_norm = np.linalg.norm(emb)
            if emb_norm == 0:
                continue
            cos_sim = float(np.dot(q_vec, emb) / (q_norm * emb_norm))
            # Convert cosine similarity to cosine distance (0 to 2, where 0 is identical)
            cos_distance = 1.0 - cos_sim
            candidates.append((chunk_id, cos_distance, item))

        candidates.sort(key=lambda x: x[1])
        top_candidates = candidates[:top_k]

        for chunk_id, distance, item in top_candidates:
            formatted_results["ids"][0].append(chunk_id)
            formatted_results["documents"][0].append(item.get("text", ""))
            formatted_results["metadatas"][0].append({
                "document_id": item.get("document_id"),
                "document_name": item.get("document_name"),
                "page_number": item.get("page_number"),
                "chunk_index": item.get("chunk_index"),
                "text": item.get("text")
            })
            formatted_results["distances"][0].append(distance)

        return formatted_results
