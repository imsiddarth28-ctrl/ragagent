import sys
import os
import asyncio

# Add app to path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

import pytest
from app.services.chunking_service import DocumentChunk
from app.services.embedding_service import EmbeddingService
from app.services.vector_store_service import VectorStoreService
from app.services.retrieval_service import RetrievalService

@pytest.mark.asyncio
async def test_semantic_retrieval():
    # 1. Prepare a test chunk
    doc_id = "test_retrieval_doc"
    chunk = DocumentChunk(
        chunk_id="chunk_retrieval_1",
        document_id=doc_id,
        document_name="retrieval_test.txt",
        text="The capital of France is Paris. It is a beautiful city known for its landmarks.",
        chunk_index=0,
        page_number=1
    )
    
    # 2. Store it
    emb_data = await EmbeddingService.generate_embeddings([chunk])
    await VectorStoreService.upsert_chunks([chunk], [emb_data[0]["embedding"]])
    
    # 3. Search for it with a semantically similar question
    query = "What is the capital city of France?"
    search_results = await RetrievalService.search(query, top_k=1)
    
    assert len(search_results["results"]) == 1
    assert "Paris" in search_results["results"][0]["text"]
    assert search_results["results"][0]["document_id"] == doc_id
    assert search_results["results"][0]["page_number"] == 1
    
    # 4. Search with a completely unrelated query
    unrelated_query = "How to bake a chocolate cake?"
    # With a strict threshold, this should return nothing or a high distance result.
    # Our default threshold is 1.2 (Squared L2). 
    # Let's test with a very strict threshold.
    strict_results = await RetrievalService.search(unrelated_query, threshold=0.5)
    assert len(strict_results["results"]) == 0

    # Cleanup
    await VectorStoreService.delete_document_chunks(doc_id)

@pytest.mark.asyncio
async def test_retrieval_top_k():
    doc_id = "test_top_k"
    chunks = [
        DocumentChunk(chunk_id=f"k_{i}", document_id=doc_id, document_name="k.txt", text=f"Fact number {i}", chunk_index=i)
        for i in range(5)
    ]
    
    embeddings = await EmbeddingService.generate_embeddings(chunks)
    await VectorStoreService.upsert_chunks(chunks, [item["embedding"] for item in embeddings])
    
    # Test top_k = 2
    res_2 = await RetrievalService.search("Fact", top_k=2)
    assert len(res_2["results"]) == 2
    
    # Test top_k = 4
    res_4 = await RetrievalService.search("Fact", top_k=4)
    assert len(res_4["results"]) == 4

    # Cleanup
    await VectorStoreService.delete_document_chunks(doc_id)
