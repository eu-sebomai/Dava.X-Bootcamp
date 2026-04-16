import re
from typing import Any

from src.clients.openai_client import client
from src.config import OPENAI_CHAT_MODEL

BLOCKED_WORDS = {
    "prost",
    "prostule",
    "proasto",
    "idiot",
    "idiota",
    "idiotule",
    "idioato",
    "dobitoc",
    "dobitoca",
    "dobitocule",
    "dobitoaco"
    "nesimtit",
    "nesimtita",
    "bou",
    "boule",
    "vaco"
    "cretin",
    "cretinule",
    "cretina",
}


def normalize_text(text: str) -> str:
    """Normalizeaza textul pentru verificari simple."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s]", " ", text)
    text = " ".join(text.split())
    return text


def contains_inappropriate_language(user_query: str) -> bool:
    """Verifica daca mesajul contine limbaj nepotrivit."""
    normalized_query = normalize_text(user_query)
    words = normalized_query.split()

    return any(word in BLOCKED_WORDS for word in words)


def build_inappropriate_language_response() -> dict[str, Any]:
    """Returneaza raspunsul pentru limbaj nepotrivit."""
    return {
        "answer": (
            "Te rog sa folosesti un limbaj respectuos. "
            "Eu te pot ajuta cu recomandari de carti si rezumate."
        ),
        "selected_title": None,
        "summary": None,
        "results": {},
    }

def classify_user_query(
    user_query: str,
    chat_history: list[dict[str, str]] | None = None,
) -> str:
    """Clasifica intentia mesajului utilizatorului."""
    messages: list[dict[str, str]] = [
        {
            "role": "system",
            "content": (
                "Clasifici mesajele utilizatorilor pentru o aplicatie care recomanda carti. "
                "Tine cont si de istoricul conversatiei. "
                "Raspunde doar cu unul dintre aceste 4 label-uri exacte, fara explicatii: "
                "book_request, small_talk, unsupported, unclear.\n\n"

                "Definitii:\n"
                "- book_request = utilizatorul cere o recomandare de carte, un rezumat, un autor, "
                "un gen, o tema, sau descrie ce ar vrea sa citeasca. Chiar daca cererea e ceva mai vaga sau ciudata, trebuie sa identifici intentia.\n"
                "- small_talk = saluturi, conversatie sociala scurta, multumiri, afectiune.\n"
                "- unsupported = utilizatorul cere ceva in afara scopului aplicatiei, cum ar fi "
                "scriere creativa, ajutor general, poezii, emailuri, teme sau alte taskuri.\n"
                "- unclear = mesaj fara sens, prea vag, sau imposibil de interpretat.\n\n"

                "Exemple:\n"
                "Mesaj: 'Vreau o carte despre razboi si supravietuire.' -> book_request\n"
                "Mesaj: 'Ce imi recomanzi daca imi plac povestile fantastice?' -> book_request\n"
                "Mesaj: 'Rezumat pentru 1984' -> book_request\n"
                "Mesaj: 'Buna' -> small_talk\n"
                "Mesaj: 'Ce faci?' -> small_talk\n"
                "Mesaj: 'Scrie-mi o poveste originala cu dragoni' -> unsupported\n"
                "Mesaj: 'Ajuta-ma la matematica' -> unsupported\n"
                "Mesaj: 'asdasd' -> unclear\n\n"

                "Raspunde doar cu label-ul exact."
            ),
        }
    ]

    if chat_history:
        messages.extend(chat_history)

    messages.append({"role": "user", "content": user_query})

    response = client.chat.completions.create(
        model=OPENAI_CHAT_MODEL,
        messages=messages,
    )

    label = response.choices[0].message.content.strip().lower()
    label = label.replace("-", "_").replace(" ", "_")

    if label not in {"book_request", "small_talk", "unsupported", "unclear"}:
        return "unclear"

    return label

def build_non_book_response(intent: str) -> dict[str, Any]:
    """Construieste raspunsuri controlate pentru mesaje care nu cer carti."""
    if intent == "small_talk":
        return {
            "answer": (
                "Salut! Eu te pot ajuta cu recomandari de carti si rezumate. "
                "Spune-mi ce fel de carte cauti sau ce teme iti plac."
            ),
            "selected_title": None,
            "summary": None,
            "results": {},
        }

    if intent == "unsupported":
        return {
            "answer": (
                "Nu te pot ajuta cu asta in aceasta aplicatie. "
                "Eu sunt construit pentru recomandari de carti si rezumate. "
                "Daca vrei, spune-mi ce fel de carte cauti."
            ),
            "selected_title": None,
            "summary": None,
            "results": {},
        }

    return {
        "answer": (
            "Nu sunt sigur ce cauti. Eu te pot ajuta cu recomandari de carti si rezumate. "
            "De exemplu, poti scrie: 'Vreau o carte despre libertate si control social'."
        ),
        "selected_title": None,
        "summary": None,
        "results": {},
    }
