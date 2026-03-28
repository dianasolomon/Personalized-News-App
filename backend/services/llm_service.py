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

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}"
    payload = {"contents": [{"parts": [{"text": prompt}]}]}
    
    try:
        async with httpx.AsyncClient() as client:
            res = await client.post(
                url, json=payload,
                headers={'Content-Type': 'application/json'},
                timeout=httpx.Timeout(10.0, connect=5.0)
            )
            if res.status_code == 200:
                text = res.json()['candidates'][0]['content']['parts'][0]['text']
                set_llm_cache(prompt_hash, text)
                return text
            else:
                print("Gemini API Error:", res.status_code, res.text[:200])
                return ""
    except Exception as e:
        print("Gemini call failed:", e)
        return ""

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
    return {
        "storyId": topic.get("topic_id", str(uuid.uuid4())),
        "storyTitle": title,
        "summary": f"Emerging story covering: {title}. Click to explore the full narrative arc powered by AI.",
        "tags": tags[:3],
        "queryTerms": query_terms,
        "momentum": momentum,
        "articles": topic.get("articles", []),
        "article_count": topic.get("article_count", 0),
    }

async def rewrite_feed_topics(story_topics: list, persona: str, interests: list) -> list:
    # Always shape raw topics first — guarantees Flutter-safe output even if Gemini fails
    shaped = [_auto_shape_topic(t) for t in story_topics]
    
    if not GEMINI_API_KEY:
        return shaped

    interest_str = ", ".join(interests) if interests else "General Business"
    
    # Send only titles to keep Gemini prompt small and fast
    topics_context = ""
    for idx, t in enumerate(shaped):
        topics_context += f"[{idx}] {t['storyTitle']} (covers ~{t['article_count']} articles)\n"

    prompt = f"""You are a financial news editor for a {persona} interested in: {interest_str}.

Rewrite these {len(shaped)} business story topic titles and provide summaries:
{topics_context}

For EACH topic index, return a JSON array with:
- storyTitle: catchy personalized title
- summary: 1-2 line summary for a {persona}
- tags: array of 1-3 tags like [\"AI\", \"Markets\"]
- queryTerms: short search phrase
- momentum: one of \"Heating Up\", \"Accelerating\", \"Cooling\"

Return ONLY a JSON array, no markdown. Keep same order as input."""

    text = (await call_gemini(prompt)).strip()
    if text.startswith("```json"): text = text[7:]
    if text.startswith("```"): text = text[3:]
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
    # 1. Prepare context with indices
    context_str = ""
    for idx, a in enumerate(articles):
        context_str += f"[{idx}] Title: {a.get('title')}\nContent: {a.get('content')[:500]}\nSource: {a.get('source')}\n\n"

    prompt = f"""
    Analyze the following recent news for the business story: '{query_terms}'.
    Extract a 5-Phase Business Story Arc for a {persona}.
    
    Article Context:
    {context_str}

    For each of the 5 phases, select the ALL relevant article indices [0-{len(articles)-1}] from the context that support this phase and provide:
    - phase_name: (Beginning, Build-up, Conflict, Turning Point, What Next)
    - title: Catchy event title
    - summary: 2-sentence explanation
    - sentiment: Positive/Negative/Neutral
    - key_players: 2-3 main entities
    - contrarian_pos: The "Bull Case" or Opportunity if this trend continues
    - contrarian_neg: The "Bear Case" or Risk if this trend breaks
    - article_indices: [list of integers from 0 to {len(articles)-1}]
    
    Return ONLY a valid JSON object:
    {{
        "phases": [
            {{
                "phase_name": "Beginning",
                "title": "...",
                "summary": "...",
                "sentiment": "Positive/Negative/Neutral",
                "key_players": ["..."],
                "contrarian_pos": "...",
                "contrarian_neg": "...",
                "article_indices": [0, 1]
            }},
            ... (repeat for all 5)
        ]
    }}
    """
    text = (await call_gemini(prompt)).strip()
    
    # Defaults / Fallback
    default_phases = [
        {"phase_name": "Beginning", "title": "Initial Rumbles", "summary": "Early indicators pointed towards a major shift in the sector.", "sentiment": "Neutral", "key_players": ["Market Observers"], "contrarian_pos": "Early movers can capture significant market share.", "contrarian_neg": "High initial uncertainty may lead to premature capital burn.", "article_url": "", "image_url": "", "source": "News Feed"},
        {"phase_name": "Build-up", "title": "Momentum Gathers", "summary": "Major players began shifting massive capital in anticipation.", "sentiment": "Positive", "key_players": ["Institutional Investors"], "contrarian_pos": "Network effects will create a massive moat for leaders.", "contrarian_neg": "Overcrowded trade risk as valuation gets ahead of fundamentals.", "article_url": "", "image_url": "", "source": "News Feed"},
        {"phase_name": "Conflict", "title": "Regulatory Pushback", "summary": "Sudden regulatory scrutiny halted the immediate expansion.", "sentiment": "Negative", "key_players": ["Regulators", "Founders"], "contrarian_pos": "Regulation will clean up the industry and favor compliant giants.", "contrarian_neg": "Innovation could be throttled or pushed to offshore jurisdictions.", "article_url": "", "image_url": "", "source": "News Feed"},
        {"phase_name": "Turning Point", "title": "The Big Pivot", "summary": "The sector aggressively evolved its core offering to survive.", "sentiment": "Neutral", "key_players": ["Tech Giants"], "contrarian_pos": "The new hybrid model is actually more scalable than the original.", "contrarian_neg": "Pivoting cost is high and user trust might be compromised.", "article_url": "", "image_url": "", "source": "News Feed"},
        {"phase_name": "What Next", "title": "Consolidation Phase", "summary": "Expect massive M&A activity as the winners buy the losers over the next 12 months.", "sentiment": "Positive", "key_players": ["Private Equity"], "contrarian_pos": "M&A will drive efficiency and better product integration.", "contrarian_neg": "Anti-trust scrutiny will likely block major transformative deals.", "article_url": "", "image_url": "", "source": "News Feed"}
    ]

    if not text:
         return {"phases": default_phases}

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
         return {"phases": default_phases}

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
