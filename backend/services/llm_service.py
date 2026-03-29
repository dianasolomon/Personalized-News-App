import os
import json
import hashlib
import httpx
import asyncio

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
# Separate key for chat so it doesn't share quota with feed/story-arc calls.
# Falls back to the main key if not set.
GEMINI_CHAT_API_KEY = os.getenv("GEMINI_CHAT_API_KEY") or GEMINI_API_KEY
from services.firebase_service import get_llm_cache, set_llm_cache

import re

def extract_key_players_offline(text: str) -> list:
    try:
        import spacy
        nlp = spacy.load("en_core_web_sm")
        doc = nlp(text)
        players = []
        seen = set()
        for ent in doc.ents:
            if ent.label_ in ["PERSON", "ORG"]:
                if ent.text not in seen and len(ent.text) > 3:
                    seen.add(ent.text)
                    players.append({"name": ent.text, "role": ent.label_})
        return players[:4]
    except Exception as e:
        words = re.findall(r'\b[A-Z][a-zA-Z]+ [A-Z][a-zA-Z]+\b', text)
        players = []
        seen = set()
        for w in words:
            if w not in seen and len(w) > 5:
                seen.add(w)
                players.append({"name": w, "role": "Entity"})
        return players[:4]

async def _call_gemini_with_key(prompt: str, api_key: str) -> str:
    """Low-level Gemini call with a specific API key."""
    if not api_key:
        return ""

    prompt_hash = hashlib.md5(prompt.encode()).hexdigest()
    persistent_cache = get_llm_cache()
    if prompt_hash in persistent_cache:
        return persistent_cache[prompt_hash]

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    payload = {"contents": [{"parts": [{"text": prompt}]}]}

    try:
        async with httpx.AsyncClient() as client:
            res = await client.post(
                url, json=payload,
                headers={'Content-Type': 'application/json'},
                timeout=httpx.Timeout(30.0, connect=5.0)
            )
            if res.status_code == 200:
                text = res.json()['candidates'][0]['content']['parts'][0]['text']
                set_llm_cache(prompt_hash, text)
                return text
            else:
                print(f"Gemini API Error ({res.status_code}):", res.text[:200])
                return ""
    except Exception as e:
        print("Gemini call failed:", e)
        return ""

async def call_gemini(prompt: str) -> str:
    """Uses the main GEMINI_API_KEY (feed + story arc)."""
    return await _call_gemini_with_key(prompt, GEMINI_API_KEY)

async def call_gemini_chat(prompt: str) -> str:
    """Uses the chat-specific key, falling back to main key."""
    return await _call_gemini_with_key(prompt, GEMINI_CHAT_API_KEY)


import uuid
import re as _re

MOMENTUM_OPTIONS = ["Heating Up", "Accelerating", "Cooling"]
TAG_MAP = {
    "ai": "AI", "openai": "AI", "gemini": "AI", "machine learning": "AI",
    "tesla": "EV", "electric vehicle": "EV", "nio": "EV", "byd": "EV",
    "energy": "Energy", "oil": "Energy", "gas": "Energy", "lng": "Energy",
    "market": "Markets", "stock": "Markets", "earnings": "Markets", "revenue": "Markets",
    "regulation": "Policy", "law": "Policy", "congress": "Policy", "government": "Policy",
    "startup": "Startups", "funding": "Startups", "venture": "Startups",
    "merger": "M&A", "acquisition": "M&A", "deal": "M&A",
}

def _auto_shape_topic(topic: dict) -> dict:
    """Guarantees every field the Flutter UI expects, based on raw cluster data."""
    title = topic.get("rough_topic_label", "Business Story")
    text_lower = title.lower()
    tags = list({v for k, v in TAG_MAP.items() if k in text_lower}) or ["Business"]
    momentum = MOMENTUM_OPTIONS[hash(title) % 3]
    query_terms = " ".join(title.split()[:5])
    
    articles = topic.get("articles", [])
    fallback_summary = ""
    if articles and articles[0].get("content"):
        content = articles[0].get("content").strip()
        # Grab the first two full sentences instead of character cutting
        sentences = content.split('.')
        if len(sentences) >= 2:
            fallback_summary = sentences[0] + '.' + sentences[1] + '.'
        else:
            fallback_summary = content
    else:
        fallback_summary = f"Recent developments regarding {title}."
        
    return {
        "storyId": topic.get("topic_id", str(uuid.uuid4())),
        "storyTitle": title,
        "summary": fallback_summary,
        "tags": tags[:3],
        "queryTerms": query_terms,
        "momentum": momentum,
        "articles": articles,
        "article_count": topic.get("article_count", 0),
    }

async def rewrite_feed_topics(story_topics: list, persona: str, interests: list) -> list:
    # Always shape raw topics first — guarantees Flutter-safe output instantly
    # We BYPASS the massive LLM rewrite here to save the strict Gemini free-tier 
    # API quota (15 RPM) entirely for the detailed Story Arc and Chatbox.
    return [_auto_shape_topic(t) for t in story_topics]
    if text.endswith("```"): text = text[:-3]

    if not text:
        print("Gemini rewrite skipped — returning auto-shaped topics")
        return shaped

    try:
        polished = json.loads(text.strip())
        for i, p in enumerate(polished):
            if i < len(shaped):
                shaped[i]["storyTitle"] = p.get("storyTitle", shaped[i]["storyTitle"])
                shaped[i]["summary"]    = p.get("summary",    shaped[i]["summary"])
                shaped[i]["tags"]       = p.get("tags",       shaped[i]["tags"])
                shaped[i]["queryTerms"] = p.get("queryTerms", shaped[i]["queryTerms"])
                shaped[i]["momentum"]   = p.get("momentum",   shaped[i]["momentum"])
        return shaped
    except Exception as e:
        print("Rewrite parse error:", e)
        return shaped

async def generate_story_arc(query_terms: str, articles: list[dict], persona: str) -> dict:
    # Keep context compact — 200 chars per article, top 3 only
    top_articles = articles[:3]
    context_lines = []
    for idx, a in enumerate(top_articles):
        snippet = (a.get('content') or a.get('description') or '')[:200]
        context_lines.append(f"[{idx}] {a.get('title','')} | {snippet}")
    context_str = "\n".join(context_lines)

    prompt = (
        f"Analyze this business story for a {persona}: '{query_terms}'.\n"
        f"Articles:\n{context_str}\n\n"
        f"Return ONLY valid JSON with exactly 5 phases in this shape:\n"
        f'{{"phases":[{{"phase_name":"Beginning","title":"...","summary":"1-2 sentences",'
        f'"sentiment":"Positive|Negative|Neutral","key_players":["..."],'
        f'"contrarian_pos":"...","contrarian_neg":"...","article_indices":[0]}},...]}}\n'
        f"Phases must be: Beginning, Build-up, Conflict, Turning Point, What Next."
    )

    text = (await call_gemini(prompt)).strip()
    
    if not text:
        pass # Will fall back later
    else:
        if text.startswith("```json"): text = text[7:].strip()
        if text.startswith("```"): text = text[3:].strip()
        if text.endswith("```"): text = text[:-3].strip()
    
    if not text:
        raise ValueError("Gemini API returned an empty response. You may have exceeded your free tier rate limit.")

    if text.startswith("```json"): text = text[7:]
    if text.startswith("```"): text = text[3:]
    if text.endswith("```"): text = text[:-3]
        
    try:
        data = json.loads(text.strip())
        phases = data.get("phases", [])
        
        # 2. Map article_indices back to metadata
        for p in phases:
            indices = p.get("article_indices", [])
            if not isinstance(indices, list):
                # Fallback if LLM provides single value or nothing
                idx = p.get("article_index", indices)
                indices = [idx] if isinstance(idx, int) else [0]
            
            p["linked_articles"] = []
            for idx in indices:
                if isinstance(idx, int) and 0 <= idx < len(articles):
                    art = articles[idx]
                    p["linked_articles"].append({
                        "url": art.get("url", ""),
                        "source": art.get("source", "News Feed"),
                        "title": art.get("title", ""),
                        "image_url": art.get("image_url", "")
                    })
            
            # Legacy fallback if no articles found through indices
            if not p["linked_articles"] and articles:
                p["linked_articles"].append({
                    "url": articles[0].get("url", ""),
                    "source": articles[0].get("source", "News Feed"),
                    "title": articles[0].get("title", ""),
                    "image_url": articles[0].get("image_url", "")
                })
                
        return {"phases": phases}
    except Exception as e:
         print("Story Arc Parse Error:", e, text)
         raise ValueError(f"Failed to generate story arc from API: {e}")

async def answer_article_question(query_terms: str, question: str, persona: str) -> str:
    """
    RAG-powered chat: retrieves real articles via vector search (no API cost),
    then sends a compact, cached prompt to Gemini.
    """
    from services.vector_service import vector_search

    # 1. Retrieve top-3 relevant articles locally (TF-IDF, zero API calls)
    retrieved = vector_search(f"{query_terms} {question}", top_k=3)

    # 2. Build compact context — max 400 chars per article to minimise tokens
    if retrieved:
        context_lines = []
        for i, art in enumerate(retrieved):
            snippet = (art.get("content") or art.get("description") or art.get("title") or "")[:400]
            src = art.get("source") or art.get("source_id") or "News"
            context_lines.append(f"[{i+1}] {art.get('title','')}\nSource: {src}\n{snippet}")
        context = "\n\n".join(context_lines)
    else:
        context = f"Topic: {query_terms}"

    # 3. Short, focused prompt — fewer tokens = fewer 429s
    prompt = (
        f"You are a smart news assistant for a {persona}.\n"
        f"Use ONLY the articles below to answer the question. "
        f"Be concise (2-3 sentences max).\n\n"
        f"--- ARTICLES ---\n{context}\n\n"
        f"Question: {question}"
    )

    ans = await call_gemini_chat(prompt)
    if not ans:
        return "API quota reached — please try again in a minute!"
    return ans

