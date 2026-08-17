import sys
import os
import asyncio

# Add app to path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

import pytest
from app.services.chunking_service import DocumentChunk
from app.services.embedding_service import EmbeddingService
from app.services.vector_store_service import VectorStoreService

@pytest.mark.asyncio
async def test_embedding_generation():
    chunk = DocumentChunk(
        chunk_id="test_1",
        document_id="doc_1",
        document_name="test.txt",
        text="This is a test document for embedding generation.",
        chunk_index=0
    )
    
    result = await EmbeddingService.generate_embeddings([chunk])
    
    assert len(result) == 1
    assert result[0]["chunk_id"] == "test_1"
    assert len(result[0]["embedding"]) == 384 # Dimension for all-MiniLM-L6-v2

@pytest.mark.asyncio
async def test_vector_store_persistence():
    chunk = DocumentChunk(
        chunk_id="test_persist_1",
        document_id="doc_persist",
        document_name="persist.txt",
        text="Persistent storage test.",
        chunk_index=0,
        page_number=5
    )
    
    # 1. Generate embedding
    embedding_data = await EmbeddingService.generate_embeddings([chunk])
    embedding = embedding_data[0]["embedding"]
    
    # 2. Store in Chroma
    await VectorStoreService.upsert_chunks([chunk], [embedding])
    
    # 3. Verify retrieval
    collection = VectorStoreService.get_collection()
    res = collection.get(ids=["test_persist_1"], include=["documents", "metadatas"])
    
    assert len(res["ids"]) == 1
    assert res["documents"][0] == "Persistent storage test."
    assert res["metadatas"][0]["document_id"] == "doc_persist"
    assert res["metadatas"][0]["page_number"] == 5

@pytest.mark.asyncio
async def test_duplicate_handling():
    doc_id = "duplicate_doc"
    chunk = DocumentChunk(
        chunk_id="chunk_1",
        document_id=doc_id,
        document_name="dup.txt",
        text="Original text",
        chunk_index=0
    )
    
    # Store original
    emb_data = await EmbeddingService.generate_embeddings([chunk])
    await VectorStoreService.upsert_chunks([chunk], [emb_data[0]["embedding"]])
    
    # Reprocess same document with different text
    chunk_new = DocumentChunk(
        chunk_id="chunk_1", # Same ID
        document_id=doc_id,
        document_name="dup.txt",
        text="Updated text",
        chunk_index=0
    )
    
    # Upsert should replace
    await VectorStoreService.upsert_chunks([chunk_new], [emb_data[0]["embedding"]])
    
    collection = VectorStoreService.get_collection()
    res = collection.get(ids=["chunk_1"])
    assert res["documents"][0] == "Updated text"
    
    # Test deletion
    await VectorStoreService.delete_document_chunks(doc_id)
    res_deleted = collection.get(ids=["chunk_1"])
    assert len(res_deleted["ids"]) == 0
