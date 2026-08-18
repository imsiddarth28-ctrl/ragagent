from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import Enum

class DocumentStatus(str, Enum):
    processing = "processing"
    ready = "ready"
    failed = "failed"

class SourceType(str, Enum):
    upload = "upload"
    web = "web"

class DocumentBase(BaseModel):
    name: str
    file_type: str
    file_size: int
    page_count: Optional[int] = None
    chunks_count: int = 0
    status: DocumentStatus = DocumentStatus.processing
    source_type: SourceType = SourceType.upload
    url: Optional[str] = None
    query_that_triggered_it: Optional[str] = None

class DocumentCreate(DocumentBase):
    storage_path: Optional[str] = None

class Document(DocumentBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
