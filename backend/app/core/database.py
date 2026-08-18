from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from sqlalchemy.pool import NullPool
from app.core.config import settings

db_url = settings.DATABASE_URL if settings.DATABASE_URL else "sqlite:///./rag_agent.db"

# Ensure postgres:// is rewritten to postgresql:// for SQLAlchemy compatibility
if db_url.startswith("postgres://"):
    db_url = db_url.replace("postgres://", "postgresql://", 1)

if db_url.startswith("sqlite"):
    engine = create_engine(
        db_url,
        connect_args={"check_same_thread": False}
    )
else:
    # Use NullPool with TCP keepalives and sslmode for Render + Supabase/cloud PostgreSQL.
    # NullPool creates clean connections and prevents stale SSL socket decryption errors.
    engine = create_engine(
        db_url,
        poolclass=NullPool,
        connect_args={
            "sslmode": "require",
            "keepalives": 1,
            "keepalives_idle": 30,
            "keepalives_interval": 10,
            "keepalives_count": 5,
        }
    )
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

class Base(DeclarativeBase):
    pass

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
