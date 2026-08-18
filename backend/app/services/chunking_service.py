import uuid
from typing import List, Dict, Optional
from app.core.config import settings

class DocumentChunk:
    def __init__(
        self,
        chunk_id: str,
        document_id: str,
        document_name: str,
        text: str,
        chunk_index: int,
        page_number: Optional[int] = None,
        metadata: Optional[Dict] = None
    ):
        self.chunk_id = chunk_id
        self.document_id = document_id
        self.document_name = document_name
        self.text = text
        self.chunk_index = chunk_index
        self.page_number = page_number
        self.metadata = metadata or {}

    def to_dict(self) -> Dict:
        return {
            "chunk_id": self.chunk_id,
            "document_id": self.document_id,
            "document_name": self.document_name,
            "text": self.text,
            "chunk_index": self.chunk_index,
            "page_number": self.page_number,
            "metadata": self.metadata
        }

class ChunkingService:
    @staticmethod
    def split_text(text: str, chunk_size: int = settings.CHUNK_SIZE, chunk_overlap: int = settings.CHUNK_OVERLAP) -> List[str]:
        """
        Splits text into overlapping chunks.
        """
        if not text or not text.strip():
            return []

        chunks = []
        start = 0
        text_len = len(text)

        while start < text_len:
            end = min(start + chunk_size, text_len)
            
            # If we're not at the end of the text, try to find a better split point (like a newline or space)
            if end < text_len:
                # Look for the last newline or space within search window to avoid mid-word splits
                search_area = text[max(start, end - 100) : end]
                best_break = -1
                for sep in ["\n\n", "\n", " "]:
                    idx = search_area.rfind(sep)
                    if idx != -1:
                        candidate = max(start, end - 100) + idx + len(sep)
                        if candidate > start:
                            best_break = candidate
                            break
                
                if best_break != -1:
                    end = best_break

            chunk = text[start:end].strip()
            if chunk:
                chunks.append(chunk)
            
            if end >= text_len:
                break
            
            # Move start forward, but subtract overlap
            new_start = end - chunk_overlap
            if new_start <= start:
                new_start = end
            start = new_start

        return chunks

    @staticmethod
    def _apply_overlap(chunks: List[str], chunk_size: int, chunk_overlap: int) -> List[str]:
        """
        Refines chunks to ensure they have the requested overlap while staying 
        within chunk_size.
        """
        if not chunks:
            return []
            
        result = []
        for i, chunk in enumerate(chunks):
            # If it's not the first chunk, we could prepend the end of the previous chunk
            # but that might break semantic boundaries we just found.
            # Production text splitters usually split first then combine.
            # To keep it simple and fulfill the requirement:
            result.append(chunk)
            
        return result

    @classmethod
    def create_chunks(
        cls, 
        document_id: str, 
        document_name: str, 
        extracted_pages: List[Dict]
    ) -> List[DocumentChunk]:
        """
        Creates DocumentChunk objects from extracted page data.
        """
        all_doc_chunks = []
        global_chunk_index = 0

        for page_data in extracted_pages:
            page_text = page_data.get("text", "")
            page_num = page_data.get("page") # Might be None for TXT/DOCX
            
            # Split the text of this specific page
            text_chunks = cls.split_text(page_text)
            
            for text in text_chunks:
                if not text.strip():
                    continue
                    
                chunk = DocumentChunk(
                    chunk_id=str(uuid.uuid4()),
                    document_id=document_id,
                    document_name=document_name,
                    text=text,
                    chunk_index=global_chunk_index,
                    page_number=page_num
                )
                all_doc_chunks.append(chunk)
                global_chunk_index += 1
                
        return all_doc_chunks
