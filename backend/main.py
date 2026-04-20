import os
from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import news, chat
import uvicorn

app = FastAPI(title="My ET - AI Personalized Newsroom")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(news.router, prefix="/api/news", tags=["News"])
app.include_router(chat.router, prefix="/api/chat", tags=["Chat"])

@app.get("/")
def read_root():
    return {"message": "Welcome to My ET Backend"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
