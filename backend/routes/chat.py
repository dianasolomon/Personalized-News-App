from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.llm_service import answer_article_question

router = APIRouter()

class ChatRequest(BaseModel):
    article_content: str
    question: str
    persona: str

@router.post("/ask")
async def ask_question(req: ChatRequest):
    answer = await answer_article_question(req.article_content, req.question, req.persona)
    return {"answer": answer}
