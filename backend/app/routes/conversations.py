from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.database import get_db
from app.schemas.conversation import Conversation, ConversationCreate, ConversationWithMessages, ConversationUpdate
from app.schemas.message import Message, MessageCreate
from app.services.conversation_service import ConversationService
from app.services.rag_service import RAGService

router = APIRouter(
    prefix="/conversations",
    tags=["Conversations"],
)

class AskRequest(BaseModel):
    question: str
    provider: str
    model: str
    api_key: str
    top_k: Optional[int] = 4

@router.post("/{conversation_id}/ask", response_model=Message)
async def ask_question(conversation_id: str, request: AskRequest, db: Session = Depends(get_db)):
    return await RAGService.ask_question(
        db=db,
        conversation_id=conversation_id,
        question=request.question,
        provider=request.provider,
        model=request.model,
        api_key=request.api_key,
        top_k=request.top_k
    )

@router.post("/", response_model=Conversation)
def create_conversation(request: ConversationCreate, db: Session = Depends(get_db)):
    return ConversationService.create_conversation(db, request.title, request.document_ids)

@router.get("/", response_model=List[Conversation])
def get_conversations(db: Session = Depends(get_db)):
    return ConversationService.get_user_conversations(db)

@router.get("/{conversation_id}", response_model=ConversationWithMessages)
def get_conversation(conversation_id: str, db: Session = Depends(get_db)):
    conversation = ConversationService.get_conversation(db, conversation_id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return conversation

@router.patch("/{conversation_id}", response_model=Conversation)
def update_conversation(conversation_id: str, request: ConversationUpdate, db: Session = Depends(get_db)):
    conversation = ConversationService.update_conversation(db, conversation_id, request.title)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return conversation

@router.delete("/{conversation_id}")
def delete_conversation(conversation_id: str, db: Session = Depends(get_db)):
    success = ConversationService.delete_conversation(db, conversation_id)
    if not success:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return {"message": "Conversation deleted"}

@router.post("/{conversation_id}/messages", response_model=Message)
def add_message(conversation_id: str, request: MessageCreate, db: Session = Depends(get_db)):
    # Verify conversation exists
    conversation = ConversationService.get_conversation(db, conversation_id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    return ConversationService.add_message(
        db=db,
        conversation_id=conversation_id,
        role=request.role,
        content=request.content
    )

@router.get("/{conversation_id}/messages", response_model=List[Message])
def get_messages(conversation_id: str, limit: int = 50, offset: int = 0, db: Session = Depends(get_db)):
    return ConversationService.get_messages(db, conversation_id, limit, offset)
