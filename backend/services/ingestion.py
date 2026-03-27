import asyncio
import os
import time
import uuid
import httpx
from dotenv import load_dotenv
load_dotenv()

from services.vector_service import (
    generate_embedding, get_vector_db, save_vector_db,
    tokenize, build_idf, cluster_articles, VECTOR_DB_FILE
)

async def fetch_live_news() -> list[dict]:
    """Fetches ~50 articles by hitting multiple NewsData.io category queries in parallel."""
    news_key = os.getenv("NEWS_API_KEY")
    if not news_key:
        print("No NEWS_API_KEY found in .env.")
        return []

    base = "https://newsdata.io/api/1/news?apikey={key}&language=en&category={cat}"
    categories = ["business", "technology", "science"]

    print(f"Fetching live news from NewsData.io ({len(categories)} categories)...")

    all_results = []
    async with httpx.AsyncClient() as client:
        for cat in categories:
            try:
                url = f"https://newsdata.io/api/1/news?apikey={news_key}&language=en&category={cat}"
                res = await client.get(url, timeout=15.0)
                if res.status_code == 200:
                    items = res.json().get("results", [])
                    print(f"  [{cat}] Got {len(items)} articles")
                    for item in items:
                        content = item.get("description", "") or item.get("content", "") or ""
                        # Skip paywalled or empty articles
                        if not content or len(content) < 30:
                            continue
                        all_results.append({
                            "title":     item.get("title", "No Title"),
                            "url":       item.get("link", ""),
                            "image_url": item.get("image_url", "") or "",
                            "source":    item.get("source_id", "Unknown"),
                            "content":   content
                        })
                elif res.status_code == 429:
                    print(f"  [{cat}] Rate limited — skipping")
                else:
                    print(f"  [{cat}] Error {res.status_code}")
            except Exception as e:
                print(f"  [{cat}] Network error: {e}")

    print(f"Total raw articles fetched: {len(all_results)}")
    return all_results


def clean_and_deduplicate(raw_articles: list[dict]) -> list[dict]:
    """Basic deduplication based on exact title match to simulate ETL cleaning."""
    seen_titles = set()
    cleaned = []
    
    for article in raw_articles:
        t = article.get("title", "").strip().lower()
        if not t or t in seen_titles:
            continue
        seen_titles.add(t)
        
        # Enforce schema metadata
        cleaned.append({
            "id": str(uuid.uuid4()),
            "title": article.get("title", "No Title"),
            "content": article.get("content", ""),
            "url": article.get("url", ""),
            "image_url": article.get("image_url", ""),
            "source": article.get("source", "Unknown"),
            "published_at": time.time(),
            "tags": [],
            "embedding": []
        })
    return cleaned

async def ingest_news():
    """
    Full pipeline:
    1. Fetch live news (3 categories, ~30-50 articles)
    2. Clean + deduplicate
    3. TF-IDF embed + store in vector DB
    4. Cluster into story topics
    5. Gemini polishes feed topics (done once, stored permanently)
    """
    print("Starting Ingestion Pipeline...")
    raw_news = await fetch_live_news()

    if not raw_news:
        print("No live news returned. Aborting ingestion.")
        return

    cleaned_articles = clean_and_deduplicate(raw_news)
    print(f"Cleaned and deduped to {len(cleaned_articles)} articles.")

    db = get_vector_db()
    db["articles"] = []  # Reset

    # Build shared IDF across all article texts
    all_tokens = [tokenize(f"{a['title']} {a['content']}") for a in cleaned_articles]
    idf = build_idf(all_tokens)

    for i, article in enumerate(cleaned_articles):
        text = f"{article['title']} {article['content']}"
        if "ai" in text.lower() or "openai" in text.lower() or "gemini" in text.lower():
            article["tags"].append("AI")
        if "ev" in text.lower() or "tesla" in text.lower() or "electric" in text.lower():
            article["tags"].append("EV")
        article["embedding"] = generate_embedding(text, idf)
        db["articles"].append(article)
        print(f"[{i+1}/{len(cleaned_articles)}] Indexed: {article['title'][:55]}")

    # Step 4: Cluster into story topics using TF-IDF similarity
    print("\nClustering articles into story topics...")
    raw_clusters = cluster_articles(db["articles"], similarity_threshold=0.25)
    print(f"Found {len(raw_clusters)} story clusters.")

    # Strip article embeddings to keep stored topics light
    for t in raw_clusters:
        for art in t.get("articles", []):
            art.pop("embedding", None)

    db["raw_clusters"] = raw_clusters
    # Remove any old feed_topics to avoid confusion
    db.pop("feed_topics", None)
    
    save_vector_db(db)
    print(f"\nIngestion complete. {len(db['articles'])} articles + {len(raw_clusters)} raw clusters saved.")

if __name__ == "__main__":
    asyncio.run(ingest_news())
