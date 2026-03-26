import requests

print("Testing Backend Logic...")

BASE_URL = "http://localhost:8000/api"

print("Fetching news feed for 'Student' persona...")
try:
    res = requests.post(f"{BASE_URL}/news/feed", json={"persona": "Student", "interests": []})
    if res.status_code == 200:
        print("Success! First article title: ", res.json()['feed'][0]['title'])
        print("AI Insights: ", res.json()['feed'][0]['ai_insights'])
    else:
        print("Error fetching news: ", res.text)
except Exception as e:
    print("Could not connect to backend. Is uvicorn running?", e)
