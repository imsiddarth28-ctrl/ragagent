from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional
from .message import Message

class ConversationBase(BaseModel):
    title: str

class ConversationCreate(ConversationBase):
    document_ids: Optional[List[str]] = None

class ConversationUpdate(BaseModel):
    title: Optional[str] = None

class Conversation(ConversationBase):
    id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class ConversationWithMessages(Conversation):
    messages: List[Message] = []
