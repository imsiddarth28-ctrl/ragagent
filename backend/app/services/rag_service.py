from sqlalchemy.orm import Session
from app.services.agent_service import AgentService

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
        Delegates question answering to the comprehensive Agent Service pipeline.
        """
        return await AgentService.run_agent_pipeline(
            db=db,
            conversation_id=conversation_id,
            question=question,
            provider=provider,
            model=model,
            api_key=api_key,
            top_k=top_k
        )
