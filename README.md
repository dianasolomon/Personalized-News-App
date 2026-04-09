# 📰 AI Personalized Newsroom

An AI-powered news platform that transforms scattered articles into structured, persona-driven insights.

Instead of reading isolated news, users experience **complete story evolution**, tailored to their perspective.

---

## 🚀 What it Does

MyET reimagines news consumption by:
- Personalizing content based on user persona (Investor, Student, Founder)
- Converting news into structured **Story Arcs** (timeline of events)
- Enabling **chat-based exploration** of news using RAG
- Tracking ongoing stories with future insights

---

## ✨ Key Features

- 🎭 Persona-based summaries for different user perspectives  
- ⏳ 5-phase Story Arcs (Beginning → Build-up → Conflict → Turning Point → What Next)  
- 💬 Context-aware AI chat (RAG-based, grounded in real news)  
- 📊 Event tracking and evolving timelines  
- 🔍 Key players, sentiment, and future outlook extraction  
- ⚡ Optimized with caching for faster responses  

---

## ⚙️ How it Works

1. Fetch real-time news via APIs  
2. Cluster articles using **TF-IDF + cosine similarity**  
3. Retrieve relevant context for a topic/query  
4. Use **Gemini 2.5 Flash** to generate structured outputs via RAG  

---

## 🛠️ Tech Stack

**Frontend:** Flutter  
**Backend:** FastAPI (Python)  
**LLM:** Gemini 2.5 Flash  
**Retrieval:** TF-IDF + cosine similarity  
**Storage/Caching:** Firebase  

---

## 🧠 Engineering Highlights

The biggest challenge was handling **non-deterministic LLM outputs** that broke UI rendering.

I solved this by:
- Adding **defensive parsing** to normalize inconsistent JSON  
- Implementing **fallback responses** to prevent crashes  
- Enforcing **strict structured prompts** for reliable outputs  

This ensured a **stable and production-ready system**.

---

## ⚡ Why This Project Stands Out

- Combines **AI + backend + product thinking**
- Moves beyond summaries → builds **structured intelligence**
- Focuses on **real user experience (chat + tracking + timelines)**

---

*Built for ET Hackathon 🚀*