from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional
from enum import Enum

class MessageRole(str, Enum):
    user = "user"
    assistant = "assistant"
    system = "system"

class MessageSourceBase(BaseModel):
    document_id: Optional[str] = None
    document_name: Optional[str] = None
    source_type: Optional[str] = "document"
    url: Optional[str] = None
    title: Optional[str] = None
    chunk_id: Optional[str] = None
    page_number: Optional[int] = None
    snippet: str
    score: Optional[float] = None

class MessageSource(MessageSourceBase):
    id: str

    class Config:
        from_attributes = True

class MessageBase(BaseModel):
    role: MessageRole
    content: str

class MessageCreate(MessageBase):
    pass

class Message(MessageBase):
    id: str
    conversation_id: str
    created_at: datetime
    sources: List[MessageSource] = []

    class Config:
        from_attributes = True
