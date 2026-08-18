from typing import Optional
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Integer, DateTime, Enum as SQLEnum, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base
import enum

class DocumentStatus(str, enum.Enum):
    processing = "processing"
    ready = "ready"
    failed = "failed"

class SourceType(str, enum.Enum):
    upload = "upload"
    web = "web"

class Document(Base):
    __tablename__ = "documents"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String, nullable=False)
    file_type: Mapped[str] = mapped_column(String, nullable=False)
    file_size: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    storage_path: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    page_count: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    chunks_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[DocumentStatus] = mapped_column(SQLEnum(DocumentStatus), default=DocumentStatus.processing)
    
    # Web Knowledge & Auto-Learning fields
    source_type: Mapped[SourceType] = mapped_column(SQLEnum(SourceType), default=SourceType.upload, index=True)
    url: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    query_that_triggered_it: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    content_hash: Mapped[Optional[str]] = mapped_column(String, nullable=True, index=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
