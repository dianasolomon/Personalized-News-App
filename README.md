# 📰 AI Personalized Newsroom

![App Banner](https://via.placeholder.com/1200x400?text=AI+Personalized+Newsroom)

Welcome to the **AI Personalized Newsroom**, an intelligent news application built for the ET Hackathon. This application reimagines how users consume news by transforming scattered articles into cohesive, persona-driven narratives and multi-phase story arcs. 

Powered by **Gemini 2.5 Flash**, the backend clusters real-world news, traces event timelines, and provides an interactive Retrieval-Augmented Generation (RAG) chatbox for users to interrogate the news in real-time.

---

## 🚀 Features

* 🎭 **Persona-Driven Content Filtering:** News summaries and insights are dynamically rewritten based on user personas (e.g., Investor, Student, Founder) to ensure high relevance and tailored vocabulary.
* ⏳ **Multi-Phase Story Arcs:** Rather than reading isolated articles, users see the evolution of a story across 5 distinct phases: *Beginning, Build-up, Conflict, Turning Point, and What Next.* 
* 💬 **Context-Grounded AI Chat (RAG):** Ask questions directly about an article. The backend queries a local Vector DB of current news to supplement the article's context, preventing AI hallucinations.
* 🛡️ **Resilient Architecture:** Implements defensive schema parsing, fail-safes, and dual-routing for AI rate limiting to ensure the Flutter UI always renders fluently, even when the LLM struggles.
* ⚡ **Cross-Platform Frontend:** Beautiful, interactive, and fully responsive user interface built using Flutter.

---

## 🛠️ Technology Stack

**Frontend (Mobile/Web)**
* [Flutter](https://flutter.dev/) - Cross-platform UI toolkit
* Dart - Programming Language

**Backend (API & AI)**
* [FastAPI](https://fastapi.tiangolo.com/) - High-performance Python web framework
* [Google Gemini API](https://ai.google.dev/) (2.5 Flash) - LLM logic, content synthesis, schema generation
* [Firebase Admin](https://firebase.google.com/) - Persistent caching and metadata storage
* **Vector DB** (Local JSON) - Embeddings for RAG search context

---

## 📂 Project Structure

```text
Personalized-News-App/
├── backend/
│   ├── services/
│   │   ├── llm_service.py     # Gemini AI orchestration & parsing
│   │   ├── vector_service.py  # Local Vector search logic for RAG
│   │   └── firebase_service.py # Caching layer
│   ├── .env                   # Environment keys (Gemini, Firebase)
│   ├── main.py                # FastAPI entry point
│   └── requirements.txt       # Python dependencies
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/           # UI Screens (Feed, Detail, etc.)
    │   ├── widgets/           # Reusable UI (Story Timeline)
    │   └── services/          # API & State management
    └── pubspec.yaml           # Flutter dependencies
```

---

## 🚦 Getting Started

### Prerequisites
* Python 3.9+
* Flutter SDK & Dart
* A Gemini API Key (`GEMINI_API_KEY_NEWS`, `GEMINI_API_KEY_CHAT`)
* (Optional) Firebase Service Account credentials for caching

### 1. Backend Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```
2. **Create a virtual environment and install dependencies:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. **Configure Environment Variables:**
   Create a `.env` file in the `backend/` directory:
   ```env
   GEMINI_API_KEY_NEWS=your_gemini_key_here
   GEMINI_API_KEY_CHAT=your_second_gemini_key_here  # Split for rate limit handling
   ```
4. **Run the FastAPI Server:**
   ```bash
   uvicorn main:app --reload
   ```
   The backend will be available at `http://localhost:8000`.

### 2. Frontend Setup

1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```
2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the Application:**
   ```bash
   flutter run
   ```
   Ensure your API target in `lib/services/api_service.dart` points to your local FastAPI server.

---

## 🧠 AI Engineering Highlights

The most challenging engineering hurdle in this project was enforcing strict, reliable JSON schemas from the LLM to prevent downstream crashes in the Flutter UI. 

This was solved through:
1. **Defensive Schema Parsing:** Catching non-deterministic AI hallucinated keys (e.g., swapping `article_index` for `article_indices`) and coercing them in the Python middleware.
2. **Fallback Degradation:** Implementing hardcoded `default_phases` for the UI to gracefully degrade to if an LLM rate-limit or parse error occurs.
3. **Zero-Shot JSON Blueprints:** Enforcing exact JSON formatting instructions deep within the system prompt templates.

---

*Built with ❤️ for the ET Hackathon.*
