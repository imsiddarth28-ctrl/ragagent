from sqlalchemy.orm import Session
from app.services.retrieval_service import RetrievalService
from app.services.llm_service import LLMService
from app.services.conversation_service import ConversationService
from app.core.config import settings
from app.models.message import MessageRole
import logging

logger = logging.getLogger(__name__)

class RAGService:
    @classmethod
    async def ask_question(
        cls,
        db: Session,
        conversation_id: str,
        question: str,
        provider: str,
        model: str,
        api_key: str,
        top_k: int = 5
    ):
        """
        Full RAG Pipeline: Retrieve -> Augment -> Generate -> Persist
        """
        # 1. Retrieve relevant context
        search_results = await RetrievalService.search(question, top_k=top_k)
        chunks = search_results.get("results", [])
        
        # 2. Format context for prompt
        context_text = ""
        sources = []
        for i, chunk in enumerate(chunks):
            context_text += f"\n---\nSource {i+1}:\n{chunk['text']}\n"
            sources.append({
                "document_id": chunk["document_id"],
                "document_name": chunk["document_name"],
                "page_number": chunk["page_number"],
                "snippet": chunk["text"],
                "score": chunk["distance"]
            })

        # 3. Get conversation history for continuity
        history_msgs = ConversationService.get_recent_messages(db, conversation_id, limit=5)
        # Reverse to get chronological order for LLM
        history = [
            {"role": m.role, "content": m.content} 
            for m in reversed(history_msgs)
        ]

        # 4. Generate Answer using LLM
        system_prompt = settings.RAG_SYSTEM_PROMPT.format(context=context_text)
        
        try:
            answer = await LLMService.generate_response(
                provider=provider,
                model=model,
                api_key=api_key,
                system_prompt=system_prompt,
                user_message=question,
                history=history
            )
        except Exception as e:
            logger.error(f"LLM Generation error: {e}")
            answer = f"Error generating answer: {str(e)}"
            # If generation fails, we still might want to save the user message

        # 5. Persist both User Question and Assistant Answer
        # Save user message
        ConversationService.add_message(db, conversation_id, MessageRole.user, question)
        
        # Save assistant answer with sources
        final_msg = ConversationService.add_message(
            db, 
            conversation_id, 
            MessageRole.assistant, 
            answer,
            sources=sources
        )

        return final_msg
