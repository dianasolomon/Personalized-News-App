import os
import json
import hashlib
import httpx
import asyncio

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
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

async def call_gemini(prompt: str) -> str:
    if not GEMINI_API_KEY:
        return ""
        
    prompt_hash = hashlib.md5(prompt.encode()).hexdigest()
    persistent_cache = get_llm_cache()
    if prompt_hash in persistent_cache:
        return persistent_cache[prompt_hash]

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={GEMINI_API_KEY}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}]
    }
    
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post(url, json=payload, headers={'Content-Type': 'application/json'}, timeout=15.0)
            if res.status_code == 200:
                text = res.json()['candidates'][0]['content']['parts'][0]['text']
                set_llm_cache(prompt_hash, text)
                return text
            else:
                print("Gemini API Error:", res.status_code, res.text[:200])
                return ""
    except Exception as e:
        print("Network Error calling Gemini:", e)
        return ""

import uuid

async def generate_story_clusters(articles: list, persona: str, interests: list) -> list:
    if not GEMINI_API_KEY or not articles:
        return []

    # Join article headlines and metadata for the prompt (free plan has no description)
    articles_text = ""
    for idx, a in enumerate(articles):
        title = a.get('title', '')
        source = a.get('source_id', a.get('source', {}).get('name', 'Unknown'))
        pub_date = a.get('pubDate', '')[:10] if a.get('pubDate') else ''
        keywords = ', '.join(a.get('keywords', []) or [])[:100]
        content = a.get('content', '') or a.get('description', '') or ''
        # Filter out paid-wall placeholder text
        if 'ONLY AVAILABLE IN PAID' in content or 'ONLY AVAILABLE IN PAID' in (a.get('description') or ''):
            content = ''
        articles_text += f"[{idx}] Title: {title} | Source: {source} | Date: {pub_date} | Keywords: {keywords}\n\n"

    interest_str = ", ".join(interests) if interests else "General Business"

    prompt = f"""
    You are an expert financial analyst tailoring content for a {persona} interested in: {interest_str}.
    I am providing you with the latest {len(articles)} raw news articles.
    Group them into 3 to 5 major ongoing "Business Stories". 
    For each story cluster, provide:
    1. A catchy 'storyTitle'
    2. A comprehensive 'summary' tailored to the persona
    3. An array of 'tags' (e.g. ['Trending', 'AI', 'Policy'])
    4. An array of 'articleKeys' (the indices of the articles that belong to this story)
    5. A short 'queryTerms' string (e.g. 'OpenAI vs Google') to fetch more historical context later
    6. A 'momentum' label (Heating Up, Accelerating, or Cooling)

    Raw Articles:
    {articles_text}

    Return ONLY a valid JSON array of these clusters. Do not wrap in markdown.
    Example output format:
    [{{
        "storyId": "unique-id-here",
        "storyTitle": "AI Race Heats Up",
        "summary": "...",
        "tags": ["AI", "Trending"],
        "articleKeys": [0, 2, 5],
        "queryTerms": "AI Race",
        "momentum": "Accelerating"
    }}]
    """
    
    text = (await call_gemini(prompt)).strip()
    
    if text.startswith("```json"): text = text[7:-3]
    elif text.startswith("```"): text = text[3:-3]
    
    if not text:
        return []

    try:
        clusters = json.loads(text.strip())
        # Inject real UUIDs
        for c in clusters:
            if "storyId" not in c or c["storyId"] == "unique-id-here":
                c["storyId"] = str(uuid.uuid4())
            # Map back the real article URLs/Images based on keys
            c["articles"] = []
            for key in c.get("articleKeys", []):
                if isinstance(key, int) and 0 <= key < len(articles):
                    c["articles"].append(articles[key])
        return clusters
    except Exception as e:
        print("Story Clustering JSON Parse Error:", e, "| Raw Text:", text)
        return []

async def generate_story_arc(query_terms: str, articles_content: str, persona: str) -> dict:
    prompt = f"""
    Analyze the following recent news covering the business story: '{query_terms}'.
    You must extract a strict 5-Phase Business Story Arc for a {persona}.
    
    Article Context:
    {articles_content}

    Return ONLY a valid JSON object matching this exact structure:
    {{
        "phases": [
            {{
                "phase_name": "Beginning",
                "title": "Short catchy title",
                "summary": "2-line summary of how this started",
                "sentiment": "Positive/Negative/Neutral",
                "key_players": ["Player 1", "Player 2"],
                "contrarian_perspective": "A strong counter-argument to this phase"
            }},
            {{
                "phase_name": "Build-up",
                "title": "...", "summary": "...", "sentiment": "...", "key_players": [], "contrarian_perspective": "..."
            }},
            {{
                "phase_name": "Conflict",
                "title": "...", "summary": "...", "sentiment": "...", "key_players": [], "contrarian_perspective": "..."
            }},
            {{
                "phase_name": "Turning Point",
                "title": "...", "summary": "...", "sentiment": "...", "key_players": [], "contrarian_perspective": "..."
            }},
            {{
                "phase_name": "What Next",
                "title": "Predictions", "summary": "Predicted outcomes", "sentiment": "...", "key_players": [], "contrarian_perspective": "Alternative forecast"
            }}
        ]
    }}
    """
    text = (await call_gemini(prompt)).strip()
    
    # Graceful Fallback
    if not text:
         return {
            "phases": [
                {"phase_name": "Beginning", "title": "Initial Rumbles", "summary": "Early indicators pointed towards a major shift in the sector.", "sentiment": "Neutral", "key_players": ["Market Observers"], "contrarian_perspective": "This was just standard seasonal volatility."},
                {"phase_name": "Build-up", "title": "Momentum Gathers", "summary": "Major players began shifting massive capital in anticipation.", "sentiment": "Positive", "key_players": ["Institutional Investors"], "contrarian_perspective": "The capital shifting was an overreaction to minor trends."},
                {"phase_name": "Conflict", "title": "Regulatory Pushback", "summary": "Sudden regulatory scrutiny halted the immediate expansion.", "sentiment": "Negative", "key_players": ["Regulators", "Founders"], "contrarian_perspective": "Regulation is actually creating a massive moat for early entrants."},
                {"phase_name": "Turning Point", "title": "The Big Pivot", "summary": "The sector aggressively evolved its core offering to survive.", "sentiment": "Neutral", "key_players": ["Tech Giants"], "contrarian_perspective": "This pivot destroys their original core value proposition."},
                {"phase_name": "What Next", "title": "Consolidation Phase", "summary": "Expect massive M&A activity as the winners buy the losers over the next 12 months.", "sentiment": "Positive", "key_players": ["Private Equity"], "contrarian_perspective": "Anti-trust laws will block any meaningful M&A, freezing the market."}
            ]
         }

    if text.startswith("```json"): text = text[7:-3]
    elif text.startswith("```"): text = text[3:-3]
        
    try:
        return json.loads(text.strip())
    except Exception as e:
         print("Story Arc Parse Error:", e, text)
         return {"error": "Failed to parse narrative payload"}

async def answer_article_question(article_content: str, question: str, persona: str) -> str:
    prompt = f"""
    You are an AI assistant helping a {persona} understand news.
    Context Article: {article_content}
    
    Question: {question}
    
    Provide a concise, helpful answer based ONLY on the context. If the answer is not in the context, say so but provide relevant general knowledge if it helps the user. Keep it simple and direct.
    """
    ans = await call_gemini(prompt)
    if not ans:
        return "I'm currently resting due to API Limits (429 Error). Please ask me again soon!"
    return ans
