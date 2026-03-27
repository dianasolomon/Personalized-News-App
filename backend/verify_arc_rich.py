import asyncio
import httpx
import json

async def verify():
    base_url = "http://127.0.0.1:8001/api/news"
    async with httpx.AsyncClient(timeout=60.0) as client:
        # 1. Get feed to find a story
        r = await client.post(f"{base_url}/feed", json={"persona": "investor", "interests": []})
        feed = r.json().get("feed", [])
        if not feed:
            print("Feed is empty.")
            return
        
        story = feed[0]
        print(f"STORY: {story.get('storyTitle')}")
        
        # 2. Get arc for this story
        arc_r = await client.post(f"{base_url}/story/arc", json={
            "queryTerms": story.get("queryTerms"),
            "articlesContext": "",
            "persona": "investor"
        })
        
        arc = arc_r.json().get("arc", {})
        phases = arc.get("phases", [])
        
        if phases:
            p = phases[0]
            print("\nVERIFICATION OF FIRST PHASE:")
            print(f"- Phase Name: {p.get('phase_name')}")
            print(f"- Summary: {p.get('summary')}")
            print(f"- Sentiment: {p.get('sentiment')}")
            print(f"- Key Players: {p.get('key_players')}")
            print(f"- Contrarian: {p.get('contrarian_perspective')[:50]}...")
            print(f"- Article URL: {p.get('article_url')}")
            print(f"- Image URL: {p.get('image_url')}")
            print(f"- Source: {p.get('source')}")

if __name__ == "__main__":
    asyncio.run(verify())
