from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
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
    engine = create_engine(
        db_url,
        pool_pre_ping=True,       # Pings DB before each query; auto-reconnects if connection was closed
        pool_recycle=300,         # Recycles idle connections every 5 minutes to prevent SSL drops
        pool_size=10,             # Base connection pool size
        max_overflow=20,          # Extra connections allowed during traffic spikes
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
