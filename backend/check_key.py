import httpx

key = "AIzaSyC_Ft7MmhpmxpL1ffOHag-2mW_b-ujGytI"
models = ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-pro"]

for model in models:
    print(f"\n--- Testing model: {model} ---")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    payload = {"contents": [{"parts": [{"text": "Say hello in one word."}]}]}

    try:
        res = httpx.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=10)
        print("Status:", res.status_code)
        if res.status_code == 200:
            print("Response:", res.json()["candidates"][0]["content"]["parts"][0]["text"])
            print(f"✅ {model} IS WORKING!")
        else:
            print("Error:", res.text[:200])
    except Exception as e:
        print(f"Failed to call {model}: {e}")
