import sys
import os
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Add app to path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from app.core.database import Base
from app.services.conversation_service import ConversationService
from app.services.document_service import DocumentService
from app.models.message import MessageRole

# Setup SQLite in-memory for testing the logic without needing a real Postgres
TEST_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

def test_create_conversation(db):
    conv = ConversationService.create_conversation(db, title="Test Conv")
    assert conv.id is not None
    assert conv.title == "Test Conv"

def test_add_message_to_conversation(db):
    conv = ConversationService.create_conversation(db, title="Chat")
    msg = ConversationService.add_message(db, conv.id, MessageRole.user, "Hello")
    
    assert msg.conversation_id == conv.id
    assert msg.content == "Hello"
    assert msg.role == MessageRole.user

def test_get_messages_order(db):
    conv = ConversationService.create_conversation(db, title="Chat")
    ConversationService.add_message(db, conv.id, MessageRole.user, "First")
    ConversationService.add_message(db, conv.id, MessageRole.assistant, "Second")
    
    messages = ConversationService.get_messages(db, conv.id)
    assert len(messages) == 2
    assert messages[0].content == "First"
    assert messages[1].content == "Second"

def test_delete_conversation_cascades(db):
    conv = ConversationService.create_conversation(db, title="To Delete")
    ConversationService.add_message(db, conv.id, MessageRole.user, "Msg")
    
    ConversationService.delete_conversation(db, conv.id)
    
    messages = ConversationService.get_messages(db, conv.id)
    assert len(messages) == 0

def test_message_sources(db):
    conv = ConversationService.create_conversation(db, title="RAG")
    sources = [
        {"document_name": "doc.pdf", "page_number": 1, "snippet": "Text from doc", "score": 0.9}
    ]
    msg = ConversationService.add_message(db, conv.id, MessageRole.assistant, "Answer", sources=sources)
    
    assert len(msg.sources) == 1
    assert msg.sources[0].snippet == "Text from doc"
    assert msg.sources[0].page_number == 1
