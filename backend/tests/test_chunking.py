import sys
import os

# Add app to path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

import pytest
from app.services.chunking_service import ChunkingService

def test_split_short_text():
    text = "Hello world"
    chunks = ChunkingService.split_text(text, chunk_size=100, chunk_overlap=0)
    assert len(chunks) == 1
    assert chunks[0] == "Hello world"

def test_split_long_text():
    text = "Word " * 100 # 500 characters
    chunks = ChunkingService.split_text(text, chunk_size=100, chunk_overlap=0)
    assert len(chunks) >= 5
    assert "".join(chunks).replace(" ", "") == text.replace(" ", "")

def test_split_overlap():
    text = "ABCDEFGHIJ" # 10 chars
    # chunk_size=4, overlap=2
    # Chunk 1: ABCD (start 0, end 4)
    # Chunk 2: CDEF (start 2, end 6)
    # Chunk 3: EFGH (start 4, end 8)
    # Chunk 4: GHIJ (start 6, end 10)
    chunks = ChunkingService.split_text(text, chunk_size=4, chunk_overlap=2)
    assert "CD" in chunks[0]
    assert chunks[1].startswith("CD")
    assert "EF" in chunks[1]
    assert chunks[2].startswith("EF")

def test_semantic_boundaries():
    text = "Paragraph one.\n\nParagraph two. This is a longer sentence."
    # Size 20 should split at the paragraph break
    chunks = ChunkingService.split_text(text, chunk_size=20, chunk_overlap=0)
    assert chunks[0] == "Paragraph one."
    assert chunks[1] == "Paragraph two. This"

def test_pdf_metadata_preservation():
    extracted_pages = [
        {"page": 1, "text": "Page 1 content."},
        {"page": 2, "text": "Page 2 content."}
    ]
    chunks = ChunkingService.create_chunks("doc123", "test.pdf", extracted_pages)
    
    assert len(chunks) >= 2
    assert chunks[0].page_number == 1
    assert chunks[0].document_id == "doc123"
    assert chunks[0].document_name == "test.pdf"
    
    # Find first chunk of page 2
    page2_chunk = next(c for c in chunks if c.page_number == 2)
    assert page2_chunk.text == "Page 2 content."

def test_txt_metadata_preservation():
    extracted_pages = [{"page": None, "text": "Text content."}]
    chunks = ChunkingService.create_chunks("doc456", "test.txt", extracted_pages)
    assert chunks[0].page_number is None
    assert chunks[0].chunk_index == 0

def test_empty_text():
    assert ChunkingService.split_text("") == []
    assert ChunkingService.split_text("   ") == []
