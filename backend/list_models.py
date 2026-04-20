import os
import httpx
import asyncio
from dotenv import load_dotenv

load_dotenv()

async def list_models():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("Error: No GEMINI_API_KEY found.")
        return

    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    async with httpx.AsyncClient() as client:
        res = await client.get(url)
        if res.status_code == 200:
            models = res.json().get("models", [])
            for m in models:
                print(f"- {m['name']} (Supported: {m['supportedGenerationMethods']})")
        else:
            print(f"Error {res.status_code}: {res.text}")

if __name__ == "__main__":
    asyncio.run(list_models())
