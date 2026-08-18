import logging
import hashlib
from datetime import datetime, timezone, timedelta
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from app.services.retrieval_service import RetrievalService
from app.services.llm_service import LLMService
from app.services.conversation_service import ConversationService
from app.services.web_search_service import WebSearchService, SearchResult
from app.services.chunking_service import ChunkingService
from app.services.embedding_service import EmbeddingService
from app.services.vector_store_service import VectorStoreService
from app.core.config import settings
from app.models.document import Document, DocumentStatus, SourceType
from app.models.document_chunk import DocumentChunkModel
from app.models.message import MessageRole
from app.models.web_search_log import WebSearchLog

logger = logging.getLogger(__name__)

class AgentService:
    """
    Intelligent Agent Pipeline that orchestrates multi-step retrieval (Local Documents + Live Web Search),
    context assembly, reasoning, citation attribution, and auto-learning persistence back into the vector store.
    """

    @classmethod
    async def run_agent_pipeline(
        cls,
        db: Session,
        conversation_id: str,
        question: str,
        provider: str,
        model: str,
        api_key: str,
        top_k: int = 5,
        threshold: float = 1.4,
        allow_web_search: bool = True
    ) -> Dict[str, Any]:
        """
        Executes the agent reasoning and retrieval pipeline:
        Step 1: Document Vector Search
        Step 2: Fallback Safety Net / Live Web Search (if confidence is low or docs empty)
        Step 3: Merged Context Assembly ([Document: ...] vs [Web: ...])
        Step 4: LLM Generation with grounding instructions
        Step 5: Auto-Learning Persistence (Ingest web findings into Vector DB with deduplication)
        Step 6: Transactional Message & Citation Persistence
        """
        # Step 1: Resolve conversation document scope
        conversation = ConversationService.get_conversation(db, conversation_id)
        document_ids = None
        if conversation and conversation.documents:
            document_ids = [doc.id for doc in conversation.documents]

        # Check for summary query
        lower_q = question.lower()
        is_summary_query = any(k in lower_q for k in [
            "summary", "summarize", "what is this", "what is the pdf", "what's the pdf", 
            "what is the document", "about", "overview", "explain the file", "key points"
        ])
        effective_top_k = max(top_k, 8) if is_summary_query else top_k

        # Step 2: Search Local Documents
        logger.info(f"Agent searching documents for: '{question}', top_k: {effective_top_k}")
        doc_search_results = await RetrievalService.search(
            query=question, 
            top_k=effective_top_k, 
            threshold=threshold,
            document_ids=document_ids
        )
        doc_chunks = doc_search_results.get("results", [])

        # Fallback to direct DB chunks if vector search returned 0 and documents exist
        if not doc_chunks and document_ids:
            query_filter = db.query(DocumentChunkModel).filter(DocumentChunkModel.document_id.in_(document_ids))
            db_fallback_chunks = query_filter.order_by(DocumentChunkModel.chunk_index.asc()).limit(effective_top_k).all()
            for c in db_fallback_chunks:
                doc_chunks.append({
                    "document_id": c.document_id,
                    "document_name": c.document_name,
                    "page_number": c.page_number,
                    "text": c.text,
                    "distance": 0.5
                })

        # Assess Document Confidence
        has_strong_doc_matches = False
        if doc_chunks:
            # Check best distance
            best_distance = min(c.get("distance", 1.0) for c in doc_chunks)
            if best_distance <= settings.WEB_SEARCH_CONFIDENCE_THRESHOLD:
                has_strong_doc_matches = True

        # Step 3: Web Search Trigger Check
        web_results: List[SearchResult] = []
        should_search_web = allow_web_search and (
            not has_strong_doc_matches or
            len(doc_chunks) == 0 or
            any(w in lower_q for w in ["latest", "news", "today", "current", "weather", "recent", "who is", "what is", "price of", "search the web", "look up"])
        )

        if should_search_web:
            # Check Daily Rate Limit
            user_id = getattr(conversation, "user_id", None) if conversation else None
            can_search = cls._check_rate_limit(db, user_id=user_id)
            
            if can_search:
                logger.info(f"Triggering Web Search for: '{question}'")
                try:
                    web_results = await WebSearchService.search(query=question, max_results=5)
                    # Log search
                    cls._log_web_search(db, query=question, user_id=user_id, conv_id=conversation_id, count=len(web_results))
                except Exception as e:
                    logger.error(f"Web search execution error: {e}")
            else:
                logger.warning("Daily web search rate limit exceeded, proceeding with document context only.")

        # Step 4: Assemble Context & Build Structured Sources
        sources = []
        context_blocks = []

        # Add Document Context
        for i, chunk in enumerate(doc_chunks):
            doc_name = chunk.get("document_name", "Document")
            page_num = chunk.get("page_number")
            page_str = f", p.{page_num}" if page_num is not None else ""
            
            context_blocks.append(
                f"[Document: {doc_name}{page_str}]\n{chunk.get('text', '').strip()}"
            )

            sources.append({
                "source_type": "document",
                "document_id": chunk.get("document_id"),
                "document_name": doc_name,
                "page_number": page_num,
                "title": doc_name,
                "snippet": chunk.get("text", "")[:300],
                "score": chunk.get("distance", 0.0)
            })

        # Add Web Context
        for i, res in enumerate(web_results):
            context_blocks.append(
                f"[Web: {res.title} ({res.url})]\n{res.content.strip()}"
            )

            sources.append({
                "source_type": "web",
                "title": res.title,
                "url": res.url,
                "document_name": res.title,
                "page_number": None,
                "snippet": res.content[:300],
                "score": res.score
            })

        has_context = len(context_blocks) > 0
        context_text = "\n\n".join(context_blocks) if has_context else "No document or web information found."

        # Step 5: Multi-turn Memory
        history_msgs = ConversationService.get_recent_messages(db, conversation_id, limit=6)
        history = [
            {"role": m.role, "content": m.content} 
            for m in reversed(history_msgs)
        ]

        # Construct Agent System Prompt
        agent_system_prompt = f"""You are an advanced AI Research Assistant equipped with Document Retrieval and Live Web Search.

AVAILABLE CONTEXT:
{context_text}

INSTRUCTIONS:
1. Answer the user's question accurately, clearly, and comprehensively using the context provided above.
2. Clearly cite your sources where appropriate:
   - For document info, reference: "[Document: filename, p.X]"
   - For web info, reference: "[Web: Title, URL]"
3. If documents and web results conflict, prefer the most relevant and up-to-date information.
4. If neither the documents nor web search contain the answer, say "I don't have enough verified information to answer this question."
5. Format your output with clean Markdown (bullet points, bold text, headings).
"""

        # Step 6: LLM Execution
        try:
            answer = await LLMService.generate_response(
                provider=provider,
                model=model,
                api_key=api_key,
                system_prompt=agent_system_prompt,
                user_message=question,
                history=history
            )
        except Exception as e:
            logger.error(f"Agent LLM error: {e}")
            answer = f"⚠️ Error communicating with AI provider ({provider}): {str(e)}"

        # Step 7: Auto-Learning — Ingest Web Findings into Knowledge Base
        if web_results:
            try:
                await cls._auto_ingest_web_results(db, query=question, web_results=web_results)
            except Exception as e:
                logger.warning(f"Auto-learning web ingestion note: {e}")

        # Step 8: Transactional Message & Citation Persistence
        try:
            ConversationService.add_message(db, conversation_id, MessageRole.user, question)
            assistant_message = ConversationService.add_message(
                db=db,
                conversation_id=conversation_id,
                role=MessageRole.assistant,
                content=answer,
                sources=sources
            )
        except Exception as e:
            logger.warning(f"Retrying message persistence after connection reset: {e}")
            db.rollback()
            ConversationService.add_message(db, conversation_id, MessageRole.user, question)
            assistant_message = ConversationService.add_message(
                db=db,
                conversation_id=conversation_id,
                role=MessageRole.assistant,
                content=answer,
                sources=sources
            )

        return assistant_message

    @classmethod
    def _check_rate_limit(cls, db: Session, user_id: Optional[str] = None) -> bool:
        """Enforces daily maximum web search limits per user."""
        try:
            since = datetime.now(timezone.utc) - timedelta(days=1)
            query = db.query(WebSearchLog).filter(WebSearchLog.created_at >= since)
            if user_id:
                query = query.filter(WebSearchLog.user_id == user_id)
            count = query.count()
            return count < settings.MAX_DAILY_WEB_SEARCHES
        except Exception as e:
            logger.warning(f"Rate limit check fallback: {e}")
            return True

    @classmethod
    def _log_web_search(cls, db: Session, query: str, user_id: Optional[str], conv_id: str, count: int):
        """Logs web search calls for auditing and cost tracking."""
        try:
            log_entry = WebSearchLog(
                user_id=user_id,
                conversation_id=conv_id,
                query=query,
                results_count=count,
                provider="tavily" if settings.TAVILY_API_KEY else "duckduckgo"
            )
            db.add(log_entry)
            db.commit()
        except Exception as e:
            logger.warning(f"Failed to log web search: {e}")
            db.rollback()

    @classmethod
    async def _auto_ingest_web_results(cls, db: Session, query: str, web_results: List[SearchResult]):
        """
        Auto-Learning: Persists useful web search findings back into the Vector Database
        and Document table with deduplication (TTL-based content hashing).
        """
        ttl_threshold = datetime.now(timezone.utc) - timedelta(days=settings.WEB_DEDUPE_TTL_DAYS)

        for res in web_results:
            if not res.content or len(res.content.strip()) < 50:
                continue

            # Compute content hash
            raw_hash_content = f"{res.url}::{res.content.strip()}"
            content_hash = hashlib.sha256(raw_hash_content.encode("utf-8")).hexdigest()

            # Dedupe check: Skip if already ingested within TTL
            existing = db.query(Document).filter(
                Document.content_hash == content_hash,
                Document.created_at >= ttl_threshold
            ).first()

            if existing:
                logger.info(f"Skipping duplicate web knowledge ingestion for: {res.url}")
                continue

            # Create new Web Knowledge Document
            doc_name = res.title[:100] if res.title else "Web Source"
            db_doc = Document(
                name=f"[Web] {doc_name}",
                file_type="web",
                file_size=len(res.content.encode("utf-8")),
                source_type=SourceType.web,
                url=res.url,
                query_that_triggered_it=query,
                content_hash=content_hash,
                page_count=1,
                status=DocumentStatus.ready
            )
            db.add(db_doc)
            db.commit()
            db.refresh(db_doc)

            # Chunk, embed, and store in vector store
            text_item = [{"page": 1, "text": f"Title: {res.title}\nSource URL: {res.url}\n\n{res.content}"}]
            chunks = ChunkingService.create_chunks(db_doc.id, db_doc.name, text_item)
            
            if chunks:
                embedding_data = await EmbeddingService.generate_embeddings(chunks)
                embeddings = [item["embedding"] for item in embedding_data]

                # Store chunk records in DB
                db_chunks = [
                    DocumentChunkModel(
                        id=chunk.chunk_id,
                        document_id=db_doc.id,
                        document_name=db_doc.name,
                        page_number=1,
                        chunk_index=chunk.chunk_index,
                        text=chunk.text,
                        embedding_json=""
                    )
                    for chunk in chunks
                ]
                db.add_all(db_chunks)

                # Upsert into Vector Store
                await VectorStoreService.upsert_chunks(chunks, embeddings)
                
                db_doc.chunks_count = len(chunks)
                db.commit()
                logger.info(f"Auto-learned and persisted web source '{res.title}' into vector database ({len(chunks)} chunks).")
