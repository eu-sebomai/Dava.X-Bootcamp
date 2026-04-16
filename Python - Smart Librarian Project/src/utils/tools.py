import json


BOOKS_PATH = "./src/data/book_summaries.json"


def load_books():
    """Citeste lista de carti din fisierul JSON"""
    with open(BOOKS_PATH, "r", encoding="utf-8") as file:
        books = json.load(file)
    return books


def build_books_dict():
    """Construieste un dictionar cu titlul ca cheie"""
    books = load_books()
    books_dict = {}

    for book in books:
        books_dict[book["title"]] = book["summary"]

    return books_dict

#build the dictionary once at module load time
BOOKS_DICT = build_books_dict()


def get_summary_by_title(title: str) -> str:
    """Returneaza rezumatul complet pentru un titlu exact"""
    if title in BOOKS_DICT:
        return BOOKS_DICT[title]

    return f"Nu am gasit un rezumat pentru titlul: {title}"
