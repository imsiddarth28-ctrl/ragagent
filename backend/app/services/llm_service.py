import asyncio
import openai
import google.generativeai as genai
import anthropic
import groq
from app.core.config import settings
from typing import List, Dict, Optional

class LLMService:
    @staticmethod
    async def generate_response(
        provider: str,
        model: str,
        api_key: str,
        system_prompt: str,
        user_message: str,
        history: Optional[List[Dict]] = None
    ) -> str:
        """
        Unified method to generate responses from different AI providers.
        """
        if not api_key or not api_key.strip():
            raise ValueError(f"API key for {provider} is required.")

        if provider == "google":
            return await LLMService._call_gemini(model, api_key, system_prompt, user_message, history)
        elif provider == "openai":
            return await LLMService._call_openai(model, api_key, system_prompt, user_message, history)
        elif provider == "anthropic":
            return await LLMService._call_anthropic(model, api_key, system_prompt, user_message, history)
        elif provider == "groq":
            return await LLMService._call_groq(model, api_key, system_prompt, user_message, history)
        else:
            raise ValueError(f"Unsupported provider: {provider}")

    @staticmethod
    async def _call_groq(model: str, api_key: str, system: str, message: str, history: Optional[List[Dict]]) -> str:
        client = groq.AsyncGroq(api_key=api_key)
        messages = [{"role": "system", "content": system}]
        if history:
            for m in history:
                if m.get("content"):
                    messages.append({"role": m["role"], "content": m["content"]})
        messages.append({"role": "user", "content": message})
        
        response = await client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.7
        )
        return response.choices[0].message.content or "No response received."

    @staticmethod
    async def _call_gemini(model: str, api_key: str, system: str, message: str, history: Optional[List[Dict]]) -> str:
        def _run():
            genai.configure(api_key=api_key)
            # Normalize model name
            clean_model = model if not model.startswith("models/") else model.replace("models/", "")
            
            try:
                model_instance = genai.GenerativeModel(
                    model_name=clean_model,
                    system_instruction=system
                )
            except Exception:
                # Fallback for models or SDK versions that don't support system_instruction arg
                model_instance = genai.GenerativeModel(model_name=clean_model)
                message_with_system = f"{system}\n\nUser Question: {message}"
                return model_instance.generate_content(message_with_system).text

            gemini_history = []
            if history:
                for m in history:
                    content = m.get("content", "").strip()
                    if content:
                        role = "user" if m.get("role") == "user" else "model"
                        gemini_history.append({"role": role, "parts": [content]})
            
            # Ensure history starts with 'user' role for Gemini API requirement
            if gemini_history and gemini_history[0]["role"] != "user":
                gemini_history.pop(0)

            if gemini_history:
                chat = model_instance.start_chat(history=gemini_history)
                response = chat.send_message(message)
            else:
                response = model_instance.generate_content(message)
            
            return response.text or "No response received."

        return await asyncio.to_thread(_run)

    @staticmethod
    async def _call_openai(model: str, api_key: str, system: str, message: str, history: Optional[List[Dict]]) -> str:
        client = openai.AsyncOpenAI(api_key=api_key)
        messages = [{"role": "system", "content": system}]
        if history:
            for m in history:
                if m.get("content"):
                    messages.append({"role": m["role"], "content": m["content"]})
        messages.append({"role": "user", "content": message})
        
        response = await client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.7
        )
        return response.choices[0].message.content or "No response received."

    @staticmethod
    async def _call_anthropic(model: str, api_key: str, system: str, message: str, history: Optional[List[Dict]]) -> str:
        client = anthropic.AsyncAnthropic(api_key=api_key)
        
        anthropic_history = []
        if history:
            for m in history:
                if m.get("content"):
                    anthropic_history.append({"role": m["role"], "content": m["content"]})
        
        # Ensure alternating user/assistant turns for Anthropic
        messages = anthropic_history + [{"role": "user", "content": message}]
        
        response = await client.messages.create(
            model=model,
            system=system,
            max_tokens=1024,
            messages=messages
        )
        return response.content[0].text or "No response received."
