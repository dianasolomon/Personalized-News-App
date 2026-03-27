import os
import json
import math
import re
import uuid
from collections import defaultdict
from dotenv import load_dotenv
load_dotenv()

VECTOR_DB_FILE = "mock_vector_db.json"

def get_vector_db():
    if not os.path.exists(VECTOR_DB_FILE):
        return {"articles": []}
    try:
        with open(VECTOR_DB_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {"articles": []}

def save_vector_db(db):
    with open(VECTOR_DB_FILE, "w") as f:
        json.dump(db, f)

# --- TF-IDF based embedding (pure Python, no API required) ---

STOPWORDS = {"a","an","the","and","or","but","in","on","at","to","for","is","it","its",
             "that","this","was","are","with","as","of","by","from","be","has","have",
             "he","she","they","we","you","i","not","no","can","will","also","after","more"}

def tokenize(text: str) -> list[str]:
    words = re.findall(r'[a-z]+', text.lower())
    return [w for w in words if w not in STOPWORDS and len(w) > 2]

def compute_tf(tokens: list[str]) -> dict:
    tf = defaultdict(float)
    for t in tokens: tf[t] += 1
    total = len(tokens) or 1
    return {k: v / total for k, v in tf.items()}

def build_idf(all_documents: list[list[str]]) -> dict:
    N = len(all_documents)
    df = defaultdict(int)
    for doc in all_documents:
        for term in set(doc):
            df[term] += 1
    return {term: math.log((N + 1) / (freq + 1)) for term, freq in df.items()}

def tfidf_vector(tokens: list[str], idf: dict) -> dict:
    tf = compute_tf(tokens)
    return {term: tf_val * idf.get(term, 0) for term, tf_val in tf.items()}

def dict_cosine_similarity(v1: dict, v2: dict) -> float:
    common = set(v1.keys()) & set(v2.keys())
    if not common: return 0.0
    dot = sum(v1[k] * v2[k] for k in common)
    norm1 = math.sqrt(sum(x*x for x in v1.values()))
    norm2 = math.sqrt(sum(x*x for x in v2.values()))
    if norm1 == 0 or norm2 == 0: return 0.0
    return dot / (norm1 * norm2)

def generate_embedding(text: str, idf: dict = None) -> dict:
    """Returns a TF-IDF dict-vector for the given text."""
    tokens = tokenize(text)
    if idf is None:
        # Build a trivial IDF from just this doc
        idf = {t: 1.0 for t in set(tokens)}
    return tfidf_vector(tokens, idf)

def vector_search(query: str, top_k: int = 5) -> list[dict]:
    """Searches the vector DB for articles semantically similar to the query using TF-IDF."""
    db = get_vector_db()
    articles = db.get("articles", [])
    if not articles:
        return []

    # Build IDF across all stored articles
    all_tokens = [tokenize(f"{a.get('title','')} {a.get('content','')}") for a in articles]
    idf = build_idf(all_tokens)

    query_vec = generate_embedding(query, idf)
    results = []

    for article in articles:
        art_text = f"{article.get('title','')} {article.get('content','')}"
        art_vec = generate_embedding(art_text, idf)
        sim = dict_cosine_similarity(query_vec, art_vec)
        retrieved = {k: v for k, v in article.items() if k != "embedding"}
        results.append((sim, retrieved))

    results.sort(key=lambda x: x[0], reverse=True)
    return [r[1] for r in results[:top_k]]

def cluster_articles(articles: list[dict], similarity_threshold: float = 0.25) -> list[dict]:
    """
    Groups related articles by TF-IDF cosine similarity.
    Returns a list of story topic clusters.
    """
    if not articles:
        return []

    # Build IDF across all articles
    all_tokens = [tokenize(f"{a.get('title','')} {a.get('content','')}") for a in articles]
    idf = build_idf(all_tokens)
    
    # Pre-compute vectors
    vecs = [generate_embedding(f"{a.get('title','')} {a.get('content','')}", idf) for a in articles]

    clusters = []
    visited = set()

    for i, a1 in enumerate(articles):
        if i in visited: continue
        current_cluster = [a1]
        visited.add(i)

        for j, a2 in enumerate(articles):
            if j in visited: continue
            sim = dict_cosine_similarity(vecs[i], vecs[j])
            if sim >= similarity_threshold:
                current_cluster.append(a2)
                visited.add(j)

        clusters.append(current_cluster)

    # Sort biggest clusters first
    clusters.sort(key=len, reverse=True)

    story_topics = []
    for c in clusters:
        cleaned_articles = [{k: v for k, v in art.items() if k != "embedding"} for art in c]
        central_title = c[0].get("title", "Unknown Story")
        story_topics.append({
            "topic_id": str(uuid.uuid4()),
            "rough_topic_label": central_title,
            "article_count": len(c),
            "articles": cleaned_articles
        })

    return story_topics
