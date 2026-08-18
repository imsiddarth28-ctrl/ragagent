import logging
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from app.services.retrieval_service import RetrievalService
from app.services.llm_service import LLMService
from app.services.conversation_service import ConversationService
from app.core.config import settings
from app.models.message import MessageRole

logger = logging.getLogger(__name__)

class AgentTool:
    """Represents a tool available to the RAG Agent."""
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description

class AgentService:
    """
    Intelligent Agent Pipeline that orchestrates multi-step retrieval,
    context filtering, reasoning, source attribution, and persistence.
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
        threshold: float = 1.4
    ) -> Dict[str, Any]:
        """
        Executes the agent reasoning and retrieval pipeline:
        Step 1: Context Resolution (Resolve conversation document scope)
        Step 2: Tool Execution (Vector Retrieval & Semantic Search)
        Step 3: Source Attribution & Context Assembly
        Step 4: LLM Generation with strict grounding instructions
        Step 5: Transactional Message & Citation Persistence
        """
        # Step 1: Resolve document scope
        conversation = ConversationService.get_conversation(db, conversation_id)
        document_ids = None
        if conversation and conversation.documents:
            document_ids = [doc.id for doc in conversation.documents]

        # Step 2: Detect if query is a summary/overview request
        lower_q = question.lower()
        is_summary_query = any(k in lower_q for k in [
            "summary", "summarize", "what is this", "what is the pdf", "what's the pdf", 
            "what is the document", "about", "overview", "explain the file", "key points"
        ])
        
        effective_top_k = max(top_k, 8) if is_summary_query else top_k

        # Step 3: Vector Search Tool
        logger.info(f"Agent searching documents with query: '{question}', top_k: {effective_top_k}")
        search_results = await RetrievalService.search(
            query=question, 
            top_k=effective_top_k, 
            threshold=threshold,
            document_ids=document_ids
        )
        chunks = search_results.get("results", [])

        # Fallback: If vector search returned 0 chunks, fetch the document chunks directly from DB!
        if not chunks:
            from app.models.document_chunk import DocumentChunkModel
            query_filter = db.query(DocumentChunkModel)
            if document_ids:
                query_filter = query_filter.filter(DocumentChunkModel.document_id.in_(document_ids))
            db_fallback_chunks = query_filter.order_by(DocumentChunkModel.chunk_index.asc()).limit(effective_top_k).all()
            
            for c in db_fallback_chunks:
                chunks.append({
                    "document_id": c.document_id,
                    "document_name": c.document_name,
                    "page_number": c.page_number,
                    "text": c.text,
                    "distance": 0.5
                })

        # Step 4: Context Assembly & Citations
        sources = []
        context_blocks = []

        for i, chunk in enumerate(chunks):
            doc_name = chunk.get("document_name", "Document")
            page_num = chunk.get("page_number")
            page_str = f", Page {page_num}" if page_num is not None else ""
            
            context_blocks.append(
                f"[Source {i+1}: {doc_name}{page_str}]\n{chunk.get('text', '').strip()}"
            )

            sources.append({
                "document_id": chunk.get("document_id"),
                "document_name": doc_name,
                "page_number": page_num,
                "snippet": chunk.get("text", "")[:300],
                "score": chunk.get("distance", 0.0)
            })

        has_context = len(context_blocks) > 0
        context_text = "\n\n".join(context_blocks) if has_context else "No document text found in the database. Please upload a PDF first."

        # Step 5: Multi-turn Conversation Memory
        history_msgs = ConversationService.get_recent_messages(db, conversation_id, limit=6)
        history = [
            {"role": m.role, "content": m.content} 
            for m in reversed(history_msgs)
        ]

        # System prompt with structured summarization & grounding
        agent_system_prompt = f"""You are an advanced RAG AI Assistant. Your goal is to provide accurate, comprehensive, and helpful answers based on the user's uploaded documents.

CONTEXT FROM DOCUMENTS:
{context_text}

INSTRUCTIONS:
1. Base your answer directly on the provided document context above.
2. If the user asks for a summary, overview, or explanation of the PDF/document (e.g. "what is the pdf about", "summarize"), provide a well-structured response with:
   - **Executive Summary / Purpose**: High-level overview of what the document covers.
   - **Key Highlights / Main Topics**: Bulleted list of crucial points, findings, or sections.
   - **Conclusion / Takeaways**: Core message or action points.
3. Cite source document names and page numbers whenever referencing facts (e.g. "[Doc: filename.pdf, p.2]").
4. Use clean Markdown formatting with headings and bullet points for readability.
"""

        # Step 5: LLM Execution
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

        # Step 6: Persist User message and Assistant response
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
