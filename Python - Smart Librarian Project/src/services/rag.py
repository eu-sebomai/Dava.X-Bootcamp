from typing import Any

from src.config import OPENAI_EMBEDDING_MODEL, OPENAI_CHAT_MODEL
from src.clients.openai_client import client

import chromadb

chroma_client = chromadb.PersistentClient(path="./chroma_db")
collection = chroma_client.get_or_create_collection(name="books")


def get_embedding(text: str) -> list[float]:
    """Genereaza embedding pentru textul introdus"""
    text = text.strip()
    if not text:
        raise ValueError("Textul pentru embedding nu poate fi gol.")

    response = client.embeddings.create(
        model=OPENAI_EMBEDDING_MODEL,
        input=text,
    )
    return response.data[0].embedding


def search_books(query: str, n_results: int = 3) -> dict[str, Any]:
    """Cauta 3 cele mai relevante carti in ChromaDB"""
    query_embedding = get_embedding(query)

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=n_results,
        include=["metadatas", "documents", "distances"],
    )
    return results


def format_context(results: dict[str, Any]) -> str:
    """Transforma rezultatele din Chroma intr-un context clar pentru model."""
    metadatas = results.get("metadatas", [[]])[0]
    documents = results.get("documents", [[]])[0]
    distances = results.get("distances", [[]])[0]

    if not metadatas:
        return "Nu au fost gasite carti relevante."

    chunks = []
    for idx, metadata in enumerate(metadatas):
        doc = documents[idx] if idx < len(documents) else ""
        distance = distances[idx] if idx < len(distances) else None

        title = metadata.get("title", "Titlu necunoscut")
        author = metadata.get("author", "Autor necunoscut")
        themes = metadata.get("themes", [])

        if isinstance(themes, list):
            themes_text = ", ".join(themes)
        else:
            themes_text = str(themes)

        block = (
            f"Cartea {idx + 1}:\n"
            f"Titlu: {title}\n"
            f"Autor: {author}\n"
            f"Teme: {themes_text}\n"
            f"Rezumat: {doc}\n"
        )

        if distance is not None:
            block += f"Distanta semantica: {distance}\n"

        chunks.append(block)

    return "\n".join(chunks)


def answer_question(query: str, n_results: int = 3) -> str:
    """Face retrieval + generation si intoarce un raspuns natural."""
    results = search_books(query, n_results=n_results)
    context = format_context(results)

    prompt = f"""
Esti un asistent care recomanda carti pe baza unei baze de date interne.

Intrebarea utilizatorului:
{query}

Context extras din baza de date:
{context}

Instructiuni:
- Recomanda 1-3 carti relevante.
- Explica pe scurt de ce se potrivesc.
- Foloseste doar informatia din context.
- Daca nu exista suficiente informatii, spune asta clar.
"""

    response = client.responses.create(
        model=OPENAI_CHAT_MODEL,
        input=prompt,
    )

    return response.output_text
