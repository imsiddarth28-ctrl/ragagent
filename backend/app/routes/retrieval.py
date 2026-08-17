from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Optional
from app.services.retrieval_service import RetrievalService
from app.core.config import settings

router = APIRouter(
    prefix="/retrieval",
    tags=["Retrieval"],
)

class SearchRequest(BaseModel):
    query: str
    top_k: Optional[int] = settings.DEFAULT_TOP_K
    threshold: Optional[float] = settings.DEFAULT_RELEVANCE_THRESHOLD

@router.post("/search")
async def search(request: SearchRequest):
    return await RetrievalService.search(
        query=request.query,
        top_k=request.top_k,
        threshold=request.threshold
    )
