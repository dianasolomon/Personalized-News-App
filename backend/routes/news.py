from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.vector_service import get_vector_db, cluster_articles, vector_search
from services.llm_service import rewrite_feed_topics, generate_story_arc

router = APIRouter()

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
    story_data: dict

@router.post("/feed")
async def get_personalized_feed(req: NewsRequest):
    db = get_vector_db()
    
    # 1. Try to get raw clusters from the database (calculated during ingestion)
    raw_clusters = db.get("raw_clusters", [])
    
    # 2. If no raw clusters exist (ingestion didn't run), fallback to live clustering
    if not raw_clusters:
        articles = db.get("articles", [])
        if not articles:
            return {"feed": []}
        raw_clusters = cluster_articles(articles, similarity_threshold=0.25)
    
    # 3. Call Gemini to polish/personalize these clusters specifically for THIS persona
    # Note: call_gemini uses a persistent cache, so this is instant for the same persona.
    personalized_feed = await rewrite_feed_topics(raw_clusters, req.persona, req.interests)
    
    return {"feed": personalized_feed}

@router.post("/story/arc")
async def get_story_arc(req: StoryArcRequest):
    # 1. Vector Search for related documents
    retrieved_articles = vector_search(req.queryTerms, top_k=5)
    
    # 2. Generate structured arc heavily grounded in the retrieved context
    # We now pass the articles list directly so it can link real URLs/images
    arc = await generate_story_arc(req.queryTerms, retrieved_articles, req.persona)
    return {"arc": arc}

@router.get("/tracked/{user_id}")
async def get_tracked(user_id: str):
    from services.firebase_service import get_tracked_stories
    return {"tracked_stories": get_tracked_stories(user_id)}

@router.post("/tracked/toggle")
async def toggle_tracked(req: ToggleTrackRequest):
    from services.firebase_service import toggle_tracked_story
    status = toggle_tracked_story(req.user_id, req.story_id, req.story_data)
    return {"status": status}
