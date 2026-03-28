# Mock Firebase implementation until service account is provided.
# In a real app, use firebase_admin.credentials.Certificate(...)

import json
import os
import time

DB_FILE = "mock_db.json"

def get_db():
    if not os.path.exists(DB_FILE):
        return {}
    try:
        with open(DB_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {}

def save_db(data):
    with open(DB_FILE, "w") as f:
        json.dump(data, f)

def get_user_persona(user_id: str):
    db = get_db()
    return db.get(user_id, {}).get("persona", "Student")

def save_user_persona(user_id: str, persona: str, interests: list):
    db = get_db()
    
    # Initialize user doc if missing
    if user_id not in db:
        db[user_id] = {}
        
    db[user_id]["persona"] = persona
    db[user_id]["interests"] = interests
    
    if "tracked_stories" not in db[user_id]:
        db[user_id]["tracked_stories"] = []
        
    save_db(db)

def get_tracked_stories(user_id: str) -> list:
    db = get_db()
    return db.get(user_id, {}).get("tracked_stories", [])

def toggle_tracked_story(user_id: str, story_id: str, story_data: dict):
    db = get_db()
    if user_id not in db: db[user_id] = {}
    if "tracked_stories" not in db[user_id]: db[user_id]["tracked_stories"] = []
    
    # Simple toggle logic
    existing = next((s for s in db[user_id]["tracked_stories"] if s["id"] == story_id), None)
    if existing:
        db[user_id]["tracked_stories"] = [s for s in db[user_id]["tracked_stories"] if s["id"] != story_id]
        status = "untracked"
    else:
        # Store the FULL story data so the frontend can navigate back to it easily
        tracked_item = {
            "id": story_id,
            "tracked_at": time.time(),
            **story_data # Merge full story data (title, summary, articles, etc)
        }
        db[user_id]["tracked_stories"].insert(0, tracked_item)
        status = "tracked"
        
    save_db(db)
    return status

def get_feed_cache(feed_hash: str):
    db = get_db()
    return db.get("feed_cache", {}).get(feed_hash)

def set_feed_cache(feed_hash: str, clusters: list):
    db = get_db()
    if "feed_cache" not in db:
        db["feed_cache"] = {}
    db["feed_cache"][feed_hash] = clusters
    save_db(db)

def get_llm_cache():
    db = get_db()
    return db.get("llm_cache", {})

def set_llm_cache(prompt_hash: str, response_text: str):
    db = get_db()
    if "llm_cache" not in db:
        db["llm_cache"] = {}
    db["llm_cache"][prompt_hash] = response_text
    save_db(db)

def get_news_cache():
    db = get_db()
    nc = db.get("news_cache", {})
    if not nc: return None
    if time.time() - nc.get("timestamp", 0) > 2 * 3600:
        return None
    return nc.get("data")

def set_news_cache(data):
    db = get_db()
    db["news_cache"] = {"timestamp": time.time(), "data": data}
    save_db(db)
