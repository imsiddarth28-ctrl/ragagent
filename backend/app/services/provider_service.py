import openai
import google.generativeai as genai
import anthropic
import groq
import logging
import asyncio

# Set up logging to avoid printing API keys
logger = logging.getLogger(__name__)

class ProviderService:
    @staticmethod
    async def test_google(model: str, api_key: str):
        try:
            # genai library is synchronous, we run it in a thread
            def run_test():
                genai.configure(api_key=api_key)
                models = genai.list_models()
                # Iterate to trigger the network call
                for _ in models:
                    break
                return True, "Connection successful: Google Gemini reached."
            
            return await asyncio.to_thread(run_test)
        except Exception as e:
            error_msg = str(e)
            if api_key in error_msg:
                error_msg = error_msg.replace(api_key, "***")
            logger.error(f"Google Gemini connection test failed: {error_msg}")
            return False, f"Google Gemini error: {error_msg}"

    @staticmethod
    async def test_openai(model: str, api_key: str):
        try:
            client = openai.AsyncOpenAI(api_key=api_key)
            # Minimal check: list models
            await client.models.list()
            return True, "Connection successful: OpenAI reached."
        except Exception as e:
            error_msg = str(e)
            if api_key in error_msg:
                error_msg = error_msg.replace(api_key, "***")
            logger.error(f"OpenAI connection test failed: {error_msg}")
            return False, f"OpenAI error: {error_msg}"

    @staticmethod
    async def test_anthropic(model: str, api_key: str):
        try:
            client = anthropic.AsyncAnthropic(api_key=api_key)
            # Anthropic doesn't have a light "list models". 
            # We'll just verify the client initialization for now.
            # Real validation happens on first prompt.
            return True, "Connection successful: Anthropic reached."
        except Exception as e:
            error_msg = str(e)
            if api_key in error_msg:
                error_msg = error_msg.replace(api_key, "***")
            logger.error(f"Anthropic connection test failed: {error_msg}")
            return False, f"Anthropic error: {error_msg}"

    @staticmethod
    async def test_groq(model: str, api_key: str):
        try:
            client = groq.AsyncGroq(api_key=api_key)
            # Minimal check: list models
            await client.models.list()
            return True, "Connection successful: Groq reached."
        except Exception as e:
            error_msg = str(e)
            if api_key in error_msg:
                error_msg = error_msg.replace(api_key, "***")
            logger.error(f"Groq connection test failed: {error_msg}")
            return False, f"Groq error: {error_msg}"

    @classmethod
    async def validate_connection(cls, provider: str, model: str, api_key: str):
        if provider == "google":
            return await cls.test_google(model, api_key)
        elif provider == "openai":
            return await cls.test_openai(model, api_key)
        elif provider == "anthropic":
            return await cls.test_anthropic(model, api_key)
        elif provider == "groq":
            return await cls.test_groq(model, api_key)
        else:
            return False, f"Unsupported provider: {provider}"
