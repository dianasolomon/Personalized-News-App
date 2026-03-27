import httpx, os
from dotenv import load_dotenv
load_dotenv()

key = os.getenv("GEMINI_API_KEY")
print(f"Testing key: {key[:15]}...")

# List all available models  
r = httpx.get(f"https://generativelanguage.googleapis.com/v1/models?key={key}", timeout=10)
print(f"\nList Models Status: {r.status_code}")
if r.status_code == 200:
    models = r.json().get("models", [])
    embed_models = [m["name"] for m in models if "embed" in m["name"].lower()]
    print(f"Embedding models available: {embed_models}")
else:
    print(f"Error: {r.text[:300]}")

# Try embedding-001 (older, more widely available)
print("\n--- Testing embedding-001 ---")
r2 = httpx.post(
    f"https://generativelanguage.googleapis.com/v1/models/embedding-001:embedContent?key={key}",
    json={"model": "models/embedding-001", "content": {"parts": [{"text": "hello world"}]}},
    timeout=10
)
print(f"Status: {r2.status_code}")
if r2.status_code == 200:
    print(f"Dimension: {len(r2.json()['embedding']['values'])}")
else:
    print(f"Error: {r2.text[:300]}")

# Try text-embedding-004
print("\n--- Testing text-embedding-004 ---")
r3 = httpx.post(
    f"https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key={key}",
    json={"model": "models/text-embedding-004", "content": {"parts": [{"text": "hello world"}]}},
    timeout=10
)
print(f"Status: {r3.status_code}")
if r3.status_code == 200:
    print(f"Dimension: {len(r3.json()['embedding']['values'])}")
else:
    print(f"Error: {r3.text[:300]}")
