import json
db = json.load(open('mock_vector_db.json'))
arts = db.get('articles', [])
print(f'Articles in DB: {len(arts)}')
for i, a in enumerate(arts):
    print(f'  [{i}] {a["title"][:70]} | emb_keys: {len(a.get("embedding", {}))}')
