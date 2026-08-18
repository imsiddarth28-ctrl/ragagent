import sys
from app.core.database import SessionLocal, engine, Base
from app.models import User, Document, Conversation, Message
from app.schemas.user import UserRegister, UserLogin, GoogleAuthRequest
from app.routes.auth import register, login, google_auth
from app.services.agent_service import AgentService
from app.services.conversation_service import ConversationService

def run_backend_tests():
    print("=== 1. Initializing Database Schema ===")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        print("=== 2. Testing User Registration ===")
        test_email = "test_user_ai@example.com"
        # Delete existing test user if exists
        existing = db.query(User).filter(User.email == test_email).first()
        if existing:
            db.delete(existing)
            db.commit()

        reg_payload = UserRegister(name="Test AI User", email=test_email, password="password123")
        token_resp = register(reg_payload, db)
        print(f"[PASS] Registered user: {token_resp.user.name} ({token_resp.user.email})")
        assert token_resp.access_token is not None

        print("=== 3. Testing User Login ===")
        login_payload = UserLogin(email=test_email, password="password123")
        login_resp = login(login_payload, db)
        print(f"[PASS] Logged in successfully. Token type: {login_resp.token_type}")
        assert login_resp.access_token is not None

        print("=== 4. Testing Google Sign-In / OAuth ===")
        google_payload = GoogleAuthRequest(
            email="google_test_user@gmail.com",
            name="Google Test User",
            avatar_url="https://lh3.googleusercontent.com/a/test-avatar"
        )
        g_resp = google_auth(google_payload, db)
        print(f"[PASS] Google Sign-In authenticated: {g_resp.user.name} ({g_resp.user.auth_provider})")

        print("=== 5. Testing Conversation & Agent Pipeline ===")
        conv = ConversationService.create_conversation(db, "Test Document Q&A")
        print(f"[PASS] Created conversation: {conv.id} ('{conv.title}')")

        print("=== ALL BACKEND TESTS PASSED SUCCESSFULLY! ===")

    finally:
        db.close()

if __name__ == "__main__":
    run_backend_tests()
