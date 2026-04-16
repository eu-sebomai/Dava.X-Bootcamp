import json

from src.config import OPENAI_EMBEDDING_MODEL
from src.clients.openai_client import client

import chromadb

def load_books(file_path: str) -> list[dict]:
    """Citeste cartile din fisierul JSON"""
    with open(file_path, "r", encoding="utf-8") as file:
        books = json.load(file)
    return books


def build_book_text(book: dict) -> str:
    """Construieste textul complet folosit pentru embedding"""
    title = book["title"]
    author = book["author"]
    themes = ", ".join(book["themes"])
    summary = book["summary"]

    text = (
        f"Titlu: {title}\n"
        f"Autor: {author}\n"
        f"Teme: {themes}\n"
        f"Rezumat: {summary}"
    )
    return text


def get_embedding(text: str) -> list[float]:
    """Genereaza embedding pentru un text folosind OpenAI"""
    response = client.embeddings.create(
        model=OPENAI_EMBEDDING_MODEL,
        input=text
    )
    return response.data[0].embedding


def create_vector_store() -> None:
    """Creeaza colectia ChromaDB si adauga toate cartile"""
    books_path = "./src/data/book_summaries.json"
    books = load_books(books_path)

    chroma_client = chromadb.PersistentClient(path="./chroma_db")
    collection = chroma_client.get_or_create_collection(name="books")

    #stergem colectia veche daca ca sa refacem indexul
    existing_items = collection.count()
    if existing_items > 0:
        print(f"Colectia are deja {existing_items} documente.")
        print("Stergem documentele vechi si reconstruim colectia...")

        all_data = collection.get()
        if all_data["ids"]:
            collection.delete(ids=all_data["ids"])

    for index, book in enumerate(books):
        book_id = str(index + 1)
        book_text = build_book_text(book)
        embedding = get_embedding(book_text)

        collection.add(
            ids=[book_id],
            embeddings=[embedding],
            documents=[book_text],
            metadatas=[{
                "title": book["title"],
                "author": book["author"],
                "summary": book["summary"],
                "themes": ", ".join(book["themes"])
            }]
        )

        print(f"Adaugata cartea: {book['title']}")

    print("Vector store creat cu succes.")


if __name__ == "__main__":
    create_vector_store()