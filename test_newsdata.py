import os
import requests
from dotenv import load_dotenv

load_dotenv("backend/.env")
key = os.getenv("NEWS_API_KEY")
print("Key starts with:", key[:5] if key else "None")
url = f"https://newsdata.io/api/1/news?apikey={key}&language=en&category=business"
res = requests.get(url)
print("Status:", res.status_code)
print("Response:", res.text)
