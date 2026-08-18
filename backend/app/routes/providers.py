from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.provider_service import ProviderService

router = APIRouter(
    prefix="/providers",
    tags=["Providers"],
)

class ConnectionTestRequest(BaseModel):
    provider: str
    model: str
    api_key: str

@router.get("/")
def get_providers():
    return [
        {
            "id": "google",
            "name": "Google Gemini",
        },
        {
            "id": "openai",
            "name": "OpenAI",
        },
        {
            "id": "anthropic",
            "name": "Anthropic",
        },
        {
            "id": "groq",
            "name": "Groq",
        },
    ]


@router.get("/{provider_id}/models")
def get_provider_models(provider_id: str):
    models = {
        "google": [
            {"id": "gemini-1.5-pro", "name": "Gemini 1.5 Pro"},
            {"id": "gemini-1.5-flash", "name": "Gemini 1.5 Flash"},
            {"id": "gemini-1.0-pro", "name": "Gemini 1.0 Pro"},
        ],
        "openai": [
            {"id": "gpt-4o", "name": "GPT-4o"},
            {"id": "gpt-4-turbo", "name": "GPT-4 Turbo"},
            {"id": "gpt-3.5-turbo", "name": "GPT-3.5 Turbo"},
        ],
        "anthropic": [
            {"id": "claude-3-5-sonnet", "name": "Claude 3.5 Sonnet"},
            {"id": "claude-3-opus", "name": "Claude 3 Opus"},
            {"id": "claude-3-haiku", "name": "Claude 3 Haiku"},
        ],
        "groq": [
            {"id": "llama3-70b-8192", "name": "Llama 3 70B"},
            {"id": "llama3-8b-8192", "name": "Llama 3 8B"},
            {"id": "mixtral-8x7b-32768", "name": "Mixtral 8x7B"},
            {"id": "gemma2-9b-it", "name": "Gemma 2 9B"},
            {"id": "openai/gpt-oss-120b", "name": "GPT OSS 120B"},
        ],
    }
    return models.get(provider_id, [])


@router.post("/test-connection")
async def test_connection(request: ConnectionTestRequest):
    if not request.api_key:
        return {
            "success": False,
            "message": "API key is required."
        }
    
    success, message = await ProviderService.validate_connection(
        provider=request.provider,
        model=request.model,
        api_key=request.api_key
    )
    
    return {
        "success": success,
        "message": message
    }
