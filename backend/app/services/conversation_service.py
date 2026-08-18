import logging
from sqlalchemy.orm import Session
from app.models.conversation import Conversation, ConversationDocument
from app.models.message import Message, MessageSource, MessageRole
from typing import List, Optional

logger = logging.getLogger(__name__)

class ConversationService:
    @staticmethod
    def create_conversation(db: Session, title: str, document_ids: Optional[List[str]] = None) -> Conversation:
        try:
            conversation = Conversation(title=title)
            db.add(conversation)
            db.commit()
            db.refresh(conversation)

            if document_ids:
                for doc_id in document_ids:
                    assoc = ConversationDocument(conversation_id=conversation.id, document_id=doc_id)
                    db.add(assoc)
                db.commit()
                db.refresh(conversation)

            return conversation
        except Exception as e:
            logger.warning(f"Error creating conversation, rolling back and retrying: {e}")
            db.rollback()
            conversation = Conversation(title=title)
            db.add(conversation)
            db.commit()
            db.refresh(conversation)
            return conversation

    @staticmethod
    def get_user_conversations(db: Session) -> List[Conversation]:
        try:
            return db.query(Conversation).order_by(Conversation.updated_at.desc()).all()
        except Exception as e:
            logger.warning(f"Error reading conversations: {e}")
            db.rollback()
            return db.query(Conversation).order_by(Conversation.updated_at.desc()).all()

    @staticmethod
    def get_conversation(db: Session, conversation_id: str) -> Optional[Conversation]:
        try:
            return db.query(Conversation).filter(Conversation.id == conversation_id).first()
        except Exception as e:
            logger.warning(f"Error reading conversation {conversation_id}: {e}")
            db.rollback()
            return db.query(Conversation).filter(Conversation.id == conversation_id).first()

    @staticmethod
    def update_conversation(db: Session, conversation_id: str, title: str) -> Optional[Conversation]:
        try:
            conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
            if conversation:
                conversation.title = title
                db.commit()
                db.refresh(conversation)
            return conversation
        except Exception as e:
            logger.warning(f"Error updating conversation: {e}")
            db.rollback()
            conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
            if conversation:
                conversation.title = title
                db.commit()
                db.refresh(conversation)
            return conversation

    @staticmethod
    def delete_conversation(db: Session, conversation_id: str) -> bool:
        try:
            conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
            if conversation:
                db.delete(conversation)
                db.commit()
                return True
            return False
        except Exception as e:
            logger.warning(f"Error deleting conversation: {e}")
            db.rollback()
            return False

    @staticmethod
    def add_message(
        db: Session, 
        conversation_id: str, 
        role: MessageRole, 
        content: str,
        sources: Optional[List[dict]] = None
    ) -> Message:
        try:
            message = Message(
                conversation_id=conversation_id,
                role=role,
                content=content
            )
            db.add(message)
            db.commit()
            db.refresh(message)

            if sources:
                for src in sources:
                    db_src = MessageSource(
                        message_id=message.id,
                        document_id=src.get("document_id"),
                        source_type=src.get("source_type", "document"),
                        url=src.get("url"),
                        title=src.get("title"),
                        chunk_id=src.get("chunk_id"),
                        page_number=src.get("page_number"),
                        snippet=src.get("snippet", ""),
                        score=src.get("score")
                    )
                    db.add(db_src)
                db.commit()
                db.refresh(message)

            return message
        except Exception as e:
            logger.warning(f"Error adding message, retrying with rollback: {e}")
            db.rollback()
            message = Message(
                conversation_id=conversation_id,
                role=role,
                content=content
            )
            db.add(message)
            db.commit()
            db.refresh(message)
            return message

    @staticmethod
    def get_messages(db: Session, conversation_id: str, limit: int = 50, offset: int = 0) -> List[Message]:
        try:
            return db.query(Message)\
                .filter(Message.conversation_id == conversation_id)\
                .order_by(Message.created_at.asc())\
                .offset(offset)\
                .limit(limit)\
                .all()
        except Exception as e:
            logger.warning(f"Error getting messages: {e}")
            db.rollback()
            return db.query(Message)\
                .filter(Message.conversation_id == conversation_id)\
                .order_by(Message.created_at.asc())\
                .offset(offset)\
                .limit(limit)\
                .all()

    @staticmethod
    def get_recent_messages(db: Session, conversation_id: str, limit: int = 10) -> List[Message]:
        try:
            return db.query(Message)\
                .filter(Message.conversation_id == conversation_id)\
                .order_by(Message.created_at.desc())\
                .limit(limit)\
                .all()
        except Exception as e:
            logger.warning(f"Error getting recent messages: {e}")
            db.rollback()
            return db.query(Message)\
                .filter(Message.conversation_id == conversation_id)\
                .order_by(Message.created_at.desc())\
                .limit(limit)\
                .all()
