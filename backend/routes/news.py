from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import requests
import os
from services.llm_service import generate_story_clusters, generate_story_arc
from services.demo_data import get_demo_feed, get_demo_arc
import hashlib

router = APIRouter()
NEWS_API_KEY = os.getenv("NEWS_API_KEY")

class NewsRequest(BaseModel):
    persona: str
    interests: list[str] = []

class StoryArcRequest(BaseModel):
    queryTerms: str
    articlesContext: str
    persona: str

class ToggleTrackRequest(BaseModel):
    user_id: str
    story_id: str
    title: str

@router.post("/feed")
async def get_personalized_feed(req: NewsRequest):
    # Using newsdata.io as the key format pub_... matches it.
    from services.firebase_service import get_news_cache, set_news_cache
    
    cached_news = get_news_cache()
    if cached_news:
        data = cached_news
    else:
        url = f"https://newsdata.io/api/1/news?apikey={NEWS_API_KEY}&q=business&language=en"
        response = requests.get(url)
        
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail=f"Failed to fetch news: {response.text}")
        
        data = response.json()
        set_news_cache(data)
        
    raw_articles = data.get("results", [])
    
    seen_titles = set()
    unique_articles = []
    for a in raw_articles:
        title = a.get("title", "")
        if title and title not in seen_titles:
            seen_titles.add(title)
            unique_articles.append(a)
            
    # Increased the cap to ingest more context for clustering
    articles = unique_articles[:15] 
    
    # Compute FeedHash
    combined_titles = "".join([a.get("title", "") for a in articles])
    feed_hash = hashlib.md5(f"{req.persona}_{''.join(req.interests)}_{combined_titles}".encode()).hexdigest()
    
    from services.firebase_service import get_feed_cache, set_feed_cache
    cached_clusters = get_feed_cache(feed_hash)
    if cached_clusters:
        return {"feed": cached_clusters}
    
    clusters = await generate_story_clusters(articles, req.persona, req.interests)
    
    # Only cache real Gemini results
    if clusters:
        set_feed_cache(feed_hash, clusters)
    else:
        # Use rich demo data — persona-specific stories
        clusters = get_demo_feed(req.persona, req.interests)
        # Inject real articles into demo clusters for realism
        for i, c in enumerate(clusters):
            start = i * 2
            c["articles"] = articles[start:start+2] if len(articles) > start else articles[:2]
        
    return {"feed": clusters}

@router.post("/story/arc")
async def get_story_arc(req: StoryArcRequest):
    # Use demo arcs (story-specific, high quality) — will try Gemini when API key has quota
    # Uncomment the lines below when Gemini is available:
    # arc = await generate_story_arc(req.queryTerms, req.articlesContext, req.persona)
    # if arc and len(arc.get("phases",[])) >= 5:
    #     return {"arc": arc}
    arc = get_demo_arc(req.queryTerms, req.persona)
    return {"arc": arc}

@router.get("/tracked/{user_id}")
async def get_tracked(user_id: str):
    from services.firebase_service import get_tracked_stories
    return {"tracked_stories": get_tracked_stories(user_id)}

@router.post("/tracked/toggle")
async def toggle_tracked(req: ToggleTrackRequest):
    from services.firebase_service import toggle_tracked_story
    status = toggle_tracked_story(req.user_id, req.story_id, req.title)
    return {"status": status}
