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

class DocumentService:
    @classmethod
    async def process_upload(cls, db: Session, file_name: str, file_content: bytes) -> Document:
        doc_id = str(uuid.uuid4())
        extension = file_name.split(".")[-1].lower()
        internal_filename = f"{doc_id}.{extension}"
        file_path = os.path.join(UPLOAD_DIR, internal_filename)

        # Save original file
        with open(file_path, "wb") as f:
            f.write(file_content)

        # Create document record in DB (processing state)
        db_doc = Document(
            id=doc_id,
            name=file_name,
            file_type=extension,
            file_size=len(file_content),
            storage_path=file_path,
            status=DocumentStatus.processing
        )
        db.add(db_doc)
        db.commit()
        db.refresh(db_doc)

        # Extract text based on type
        text_content = []
        pages_count = 0
        status = DocumentStatus.ready

        try:
            if extension == "pdf":
                text_content, pages_count = cls._extract_pdf(file_path)
            elif extension == "docx":
                text_content, pages_count = cls._extract_docx(file_path)
            elif extension == "txt":
                text_content, pages_count = cls._extract_txt(file_path)
            else:
                raise Exception(f"Unsupported file type: {extension}")
            
            # Save extracted text
            extraction_path = os.path.join(EXTRACTED_DIR, f"{doc_id}.json")
            with open(extraction_path, "w", encoding="utf-8") as f:
                json.dump({
                    "doc_id": doc_id,
                    "name": file_name,
                    "pages": text_content
                }, f, ensure_ascii=False, indent=4)

            # Create Chunks
            chunks = ChunkingService.create_chunks(doc_id, file_name, text_content)
            
            # Save chunks to disk
            chunks_path = os.path.join(CHUNKS_DIR, f"{doc_id}.json")
            with open(chunks_path, "w", encoding="utf-8") as f:
                json.dump([c.to_dict() for c in chunks], f, ensure_ascii=False, indent=4)

            chunks_count = len(chunks)

            # Generate Embeddings
            embedding_data = await EmbeddingService.generate_embeddings(chunks)
            embeddings = [item["embedding"] for item in embedding_data]

            # Store in ChromaDB
            await VectorStoreService.delete_document_chunks(doc_id)
            await VectorStoreService.upsert_chunks(chunks, embeddings)
            
            # Update record
            db_doc.page_count = pages_count
            db_doc.chunks_count = chunks_count
            db_doc.status = DocumentStatus.ready
            print(f"✅ Success: Document '{file_name}' processed. {chunks_count} chunks stored in ChromaDB.")

        except Exception as e:
            print(f"❌ Error: Document processing failed for '{file_name}': {e}")
            db_doc.status = DocumentStatus.failed
        
        db.commit()
        db.refresh(db_doc)
        return db_doc

    @staticmethod
    def _extract_pdf(path: str) -> Tuple[List[Dict], int]:
        pages = []
        doc = fitz.open(path)
        for i, page in enumerate(doc):
            pages.append({
                "page": i + 1,
                "text": page.get_text()
            })
        return pages, len(doc)

    @staticmethod
    def _extract_docx(path: str) -> Tuple[List[Dict], int]:
        doc = DocxDocument(path)
        full_text = "\n".join([para.text for para in doc.paragraphs])
        return [{"page": 1, "text": full_text}], 1

    @staticmethod
    def _extract_txt(path: str) -> Tuple[List[Dict], int]:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read()
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
            # 1. Delete from ChromaDB
            await VectorStoreService.delete_document_chunks(doc_id)

            # 2. Delete local files
            paths_to_delete = [
                doc.storage_path,
                os.path.join(EXTRACTED_DIR, f"{doc_id}.json"),
                os.path.join(CHUNKS_DIR, f"{doc_id}.json")
            ]
            for path in paths_to_delete:
                if os.path.exists(path):
                    os.remove(path)

            # 3. Delete from PostgreSQL
            db.delete(doc)
            db.commit()
            return True
        except Exception as e:
            print(f"❌ Error deleting document {doc_id}: {e}")
            db.rollback()
            return False
