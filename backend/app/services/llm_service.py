import openai
import google.generativeai as genai
import anthropic
from app.core.config import settings
from typing import List, Dict

class LLMService:
    @staticmethod
    async def generate_response(
        provider: str,
        model: str,
        api_key: str,
        system_prompt: str,
        user_message: str,
        history: List[Dict] = None
    ) -> str:
        """
        Unified method to generate responses from different AI providers.
        """
        if provider == "google":
            return await LLMService._call_gemini(model, api_key, system_prompt, user_message, history)
        elif provider == "openai":
            return await LLMService._call_openai(model, api_key, system_prompt, user_message, history)
        elif provider == "anthropic":
            return await LLMService._call_anthropic(model, api_key, system_prompt, user_message, history)
        else:
            raise ValueError(f"Unsupported provider: {provider}")

    @staticmethod
    async def _call_gemini(model: str, api_key: str, system: str, message: str, history: List[Dict]) -> str:
        genai.configure(api_key=api_key)
        # Gemini usually takes system instruction in the model constructor
        model_instance = genai.GenerativeModel(
            model_name=model,
            system_instruction=system
        )
        # Format history for Gemini
        gemini_history = []
        if history:
            for m in history:
                role = "user" if m["role"] == "user" else "model"
                gemini_history.append({"role": role, "parts": [m["content"]]})
        
        chat = model_instance.start_chat(history=gemini_history)
        response = await chat.send_message_async(message)
        return response.text

    @staticmethod
    async def _call_openai(model: str, api_key: str, system: str, message: str, history: List[Dict]) -> str:
        client = openai.AsyncOpenAI(api_key=api_key)
        messages = [{"role": "system", "content": system}]
        if history:
            for m in history:
                messages.append({"role": m["role"], "content": m["content"]})
        messages.append({"role": "user", "content": message})
        
        response = await client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.7
        )
        return response.choices[0].message.content

    @staticmethod
    async def _call_anthropic(model: str, api_key: str, system: str, message: str, history: List[Dict]) -> str:
        client = anthropic.AsyncAnthropic(api_key=api_key)
        
        anthropic_history = []
        if history:
            for m in history:
                anthropic_history.append({"role": m["role"], "content": m["content"]})
        
        response = await client.messages.create(
            model=model,
            system=system,
            max_tokens=1024,
            messages=anthropic_history + [{"role": "user", "content": message}]
        )
        return response.content[0].text
