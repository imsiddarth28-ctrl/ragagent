from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import Enum

class DocumentStatus(str, Enum):
    processing = "processing"
    ready = "ready"
    failed = "failed"

class DocumentBase(BaseModel):
    name: str
    file_type: str
    file_size: int
    page_count: Optional[int] = None
    chunks_count: int = 0
    status: DocumentStatus = DocumentStatus.processing

class DocumentCreate(DocumentBase):
    storage_path: str

class Document(DocumentBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
