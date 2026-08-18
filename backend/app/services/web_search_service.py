import logging
import asyncio
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List, Optional
from app.core.config import settings

logger = logging.getLogger(__name__)

@dataclass
class SearchResult:
    title: str
    url: str
    content: str
    published_date: Optional[str] = None
    score: float = 1.0

class BaseWebSearchProvider(ABC):
    @abstractmethod
    async def search(self, query: str, max_results: int = 5) -> List[SearchResult]:
        pass

class TavilySearchProvider(BaseWebSearchProvider):
    def __init__(self, api_key: str):
        self.api_key = api_key

    async def search(self, query: str, max_results: int = 5) -> List[SearchResult]:
        if not self.api_key:
            return []

        def _run_tavily():
            try:
                from tavily import TavilyClient
                client = TavilyClient(api_key=self.api_key)
                response = client.search(
                    query=query,
                    search_depth="basic",
                    max_results=max_results,
                    include_answer=False
                )
                results = []
                for item in response.get("results", []):
                    results.append(
                        SearchResult(
                            title=item.get("title", "Web Source"),
                            url=item.get("url", ""),
                            content=item.get("content", "").strip(),
                            published_date=item.get("published_date"),
                            score=float(item.get("score", 1.0))
                        )
                    )
                return results
            except Exception as e:
                logger.error(f"Tavily search error: {e}")
                return None

        results = await asyncio.to_thread(_run_tavily)
        return results if results is not None else []

class DuckDuckGoSearchProvider(BaseWebSearchProvider):
    async def search(self, query: str, max_results: int = 5) -> List[SearchResult]:
        def _run_ddg():
            try:
                from duckduckgo_search import DDGS
                with DDGS() as ddgs:
                    raw_results = list(ddgs.text(query, max_results=max_results))
                
                results = []
                for item in raw_results:
                    results.append(
                        SearchResult(
                            title=item.get("title", "Web Search Result"),
                            url=item.get("href", "") or item.get("url", ""),
                            content=item.get("body", "").strip(),
                            published_date=None,
                            score=0.9
                        )
                    )
                return results
            except Exception as e:
                logger.warning(f"DuckDuckGo search error: {e}")
                return []

        return await asyncio.to_thread(_run_ddg)

class WebSearchService:
    """
    Unified Web Search Service that delegates to Tavily (if API key configured)
    or falls back automatically to DuckDuckGo (free, zero-key).
    """

    @classmethod
    async def search(cls, query: str, max_results: int = 5) -> List[SearchResult]:
        api_key = settings.TAVILY_API_KEY.strip() if settings.TAVILY_API_KEY else ""

        # 1. Try Tavily if key is provided
        if api_key:
            logger.info(f"Executing web search with Tavily for query: '{query}'")
            tavily_provider = TavilySearchProvider(api_key=api_key)
            results = await tavily_provider.search(query, max_results=max_results)
            if results:
                return results
            logger.warning("Tavily search returned empty or failed, falling back to DuckDuckGo...")

        # 2. Free DuckDuckGo Fallback
        logger.info(f"Executing free web search with DuckDuckGo for query: '{query}'")
        ddg_provider = DuckDuckGoSearchProvider()
        return await ddg_provider.search(query, max_results=max_results)
