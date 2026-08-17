import os
import uuid
import json
import fitz  # PyMuPDF
from docx import Document as DocxDocument
from typing import List, Dict, Optional, Tuple
from sqlalchemy.orm import Session
from app.models.document import Document, DocumentStatus
from app.services.chunking_service import ChunkingService
from app.services.embedding_service import EmbeddingService
from app.services.vector_store_service import VectorStoreService

UPLOAD_DIR = "uploads"
EXTRACTED_DIR = "extracted_text"
CHUNKS_DIR = "chunks"

# Ensure directories exist
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(EXTRACTED_DIR, exist_ok=True)
os.makedirs(CHUNKS_DIR, exist_ok=True)

from supabase import create_client, Client
from app.core.config import settings

# Global Supabase client for storage
supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

class DocumentService:
    @classmethod
    async def process_upload(cls, db: Session, file_name: str, file_content: bytes) -> Document:
        doc_id = str(uuid.uuid4())
        extension = file_name.split(".")[-1].lower()
        internal_filename = f"{doc_id}.{extension}"

        # 1. Upload to Supabase Storage
        try:
            supabase.storage.from_(settings.SUPABASE_BUCKET).upload(
                path=internal_filename,
                file=file_content,
                file_options={"content-type": f"application/{extension}"}
            )
            storage_path = internal_filename
        except Exception as e:
            print(f"❌ Storage upload failed: {e}")
            raise Exception("Failed to upload file to cloud storage.")

        # 2. Create document record in DB (processing state)
        db_doc = Document(
            id=doc_id,
            name=file_name,
            file_type=extension,
            file_size=len(file_content),
            storage_path=storage_path,
            status=DocumentStatus.processing
        )
        db.add(db_doc)
        db.commit()
        db.refresh(db_doc)

        # 3. Extract text (We process the bytes directly since they are already in memory)
        text_content = []
        pages_count = 0
        
        try:
            if extension == "pdf":
                text_content, pages_count = cls._extract_pdf_bytes(file_content)
            elif extension == "docx":
                text_content, pages_count = cls._extract_docx_bytes(file_content)
            elif extension == "txt":
                text_content, pages_count = cls._extract_txt_bytes(file_content)
            else:
                raise Exception(f"Unsupported file type: {extension}")
            
            # 4. Create Chunks
            chunks = ChunkingService.create_chunks(doc_id, file_name, text_content)
            chunks_count = len(chunks)

            # 5. Generate Embeddings & Store in pgvector
            embedding_data = await EmbeddingService.generate_embeddings(chunks)
            embeddings = [item["embedding"] for item in embedding_data]

            await VectorStoreService.upsert_chunks(chunks, embeddings)
            
            # Update record
            db_doc.page_count = pages_count
            db_doc.chunks_count = chunks_count
            db_doc.status = DocumentStatus.ready
            print(f"✅ Success: Document '{file_name}' processed.")

        except Exception as e:
            print(f"❌ Error: {e}")
            db_doc.status = DocumentStatus.failed
        
        db.commit()
        db.refresh(db_doc)
        return db_doc

    @staticmethod
    def _extract_pdf_bytes(content: bytes) -> Tuple[List[Dict], int]:
        pages = []
        doc = fitz.open(stream=content, filetype="pdf")
        for i, page in enumerate(doc):
            pages.append({"page": i + 1, "text": page.get_text()})
        return pages, len(doc)

    @staticmethod
    def _extract_docx_bytes(content: bytes) -> Tuple[List[Dict], int]:
        from io import BytesIO
        doc = DocxDocument(BytesIO(content))
        full_text = "\n".join([para.text for para in doc.paragraphs])
        return [{"page": 1, "text": full_text}], 1

    @staticmethod
    def _extract_txt_bytes(content: bytes) -> Tuple[List[Dict], int]:
        text = content.decode("utf-8", errors="ignore")
        return [{"page": 1, "text": text}], 1

    @classmethod
    def get_all_documents(cls, db: Session) -> List[Document]:
        return db.query(Document).order_by(Document.created_at.desc()).all()

    @classmethod
    def get_document(cls, db: Session, doc_id: str) -> Optional[Document]:
        return db.query(Document).filter(Document.id == doc_id).first()

    @classmethod
    async def delete_document(cls, db: Session, doc_id: str) -> bool:
        doc = cls.get_document(db, doc_id)
        if not doc:
            return False

        try:
            # 1. Delete from ChromaDB/Vector Store
            await VectorStoreService.delete_document_chunks(doc_id)

            # 2. Delete from Supabase Storage
            try:
                supabase.storage.from_(settings.SUPABASE_BUCKET).remove([doc.storage_path])
            except Exception as e:
                print(f"⚠️ Warning: Could not remove file from storage: {e}")

            # 3. Delete from PostgreSQL
            db.delete(doc)
            db.commit()
            return True
        except Exception as e:
            print(f"❌ Error deleting document {doc_id}: {e}")
            db.rollback()
            return False
