from fastapi import APIRouter
from pydantic import BaseModel
from services.llm_service import answer_article_question

router = APIRouter()

class ChatRequest(BaseModel):
    query_terms: str        # Used for RAG vector search
    question: str
    persona: str

@router.post("/ask")
async def ask_question(req: ChatRequest):
    answer = await answer_article_question(req.query_terms, req.question, req.persona)
    return {"answer": answer}
