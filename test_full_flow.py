import os
from dotenv import load_dotenv
load_dotenv("backend/.env")

import sys
sys.path.append(os.path.join(os.path.dirname(__file__), "backend"))

from backend.routes.news import get_personalized_feed, NewsRequest
import asyncio

async def test():
    req = NewsRequest(persona="Student", interests=[])
    try:
        res = await get_personalized_feed(req)
        print("Success! First article AI Insights:")
        for k, v in res['feed'][0]['ai_insights'].items():
            print(f"{k}: {v}")
    except Exception as e:
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test())
