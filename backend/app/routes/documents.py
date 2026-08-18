from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.document_service import DocumentService

router = APIRouter(
    prefix="/documents",
    tags=["Documents"],
)

@router.post("/upload")
async def upload_document(file: UploadFile = File(...), db: Session = Depends(get_db)):
    # Validate extension
    allowed_extensions = ["pdf", "docx", "txt"]
    extension = file.filename.split(".")[-1].lower()
    
    if extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail=f"File type {extension} not supported.")

    content = await file.read()
    doc_info = await DocumentService.process_upload(db, file.filename, content)
    
    return doc_info

from typing import Optional

@router.get("/")
def get_documents(source_type: Optional[str] = None, db: Session = Depends(get_db)):
    return DocumentService.get_all_documents(db, source_type=source_type)

@router.get("/{doc_id}")
def get_document(doc_id: str, db: Session = Depends(get_db)):
    doc = DocumentService.get_document(db, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return doc

@router.delete("/{doc_id}")
async def delete_document(doc_id: str, db: Session = Depends(get_db)):
    success = await DocumentService.delete_document(db, doc_id)
    if not success:
        raise HTTPException(status_code=404, detail="Document not found")
    return {"message": "Document deleted successfully"}
