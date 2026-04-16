import json
from typing import Any

from src.clients.openai_client import client
from src.config import OPENAI_CHAT_MODEL
from src.services.rag import search_books
from src.utils.tools import get_summary_by_title
from src.utils.conversation_control import (
    contains_inappropriate_language,
    build_inappropriate_language_response,
    classify_user_query,
    build_non_book_response,
)

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "get_summary_by_title",
            "description": "Returneaza rezumatul complet pentru un titlu exact de carte.",
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {
                        "type": "string",
                        "description": "Titlul exact al cartii",
                    }
                },
                "required": ["title"],
            },
        },
    }
]


def build_context(results: dict[str, Any]) -> str:
    """Construieste contextul din rezultatele RAG."""
    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]
    distances = results.get("distances", [[]])[0]

    context_parts = []

    for index, doc in enumerate(documents):
        metadata = metadatas[index] if index < len(metadatas) else {}
        title = metadata.get("title", "Necunoscut")
        author = metadata.get("author", "Necunoscut")
        themes = metadata.get("themes", "")
        distance = distances[index] if index < len(distances) else None

        context_block = (
            f"Cartea {index + 1}:\n"
            f"Titlu: {title}\n"
            f"Autor: {author}\n"
            f"Teme: {themes}\n"
            f"Continut: {doc}\n"
        )

        if distance is not None:
            context_block += f"Distanta semantica: {distance}\n"

        context_parts.append(context_block)

    return "\n\n".join(context_parts)


def build_messages(
    user_query: str,
    context: str,
    chat_history: list[dict[str, str]] | None = None,
) -> list[dict[str, str]]:
    """Construieste mesajele trimise modelului."""
    system_message = (
        "Esti un bibliotecar AI inteligent si prietenos. "
        "Raspunzi in limba romana. "
        "Tine cont de istoricul conversatiei cand raspunzi. "
        "Daca utilizatorul cere o recomandare de carte, mai intai recomanzi o singura carte "
        "din contextul primit. Daca nu exista carti relevante sau care sunt foarte sunt ceva mai departe de cerera primita, spune ca nu ai gasit nimic potrivit. Nu incerca sa dai mereu un raspuns."
        "Dupa ce alegi cartea, trebuie sa folosesti tool-ul get_summary_by_title pentru a obtine "
        "rezumatul complet. "
        "Nu raspunde final inainte sa folosesti tool-ul. "
        "Alege doar titluri care exista exact in context. "
        "In raspunsul final structureaza clar astfel: "
        "1) Recomandare, 2) De ce se potriveste (Ce experienta au avut alti cititori atunci cand au citit aceasta carte), 3) Rezumat complet."
    )

    user_message = (
        f"Intrebarea utilizatorului este:\n{user_query}\n\n"
        f"Acesta este contextul RAG cu cartile relevante:\n{context}\n\n"
        "Alege cea mai potrivita carte si apoi foloseste tool-ul pentru a obtine rezumatul complet."
    )

    messages: list[dict[str, str]] = [
        {"role": "system", "content": system_message},
    ]

    if chat_history:
        messages.extend(chat_history)

    messages.append({"role": "user", "content": user_message})

    return messages


def run_chatbot(
    user_query: str,
    chat_history: list[dict[str, str]] | None = None,
) -> dict[str, Any]:
    """Ruleaza flow-ul complet: guardrails -> RAG -> LLM -> tool -> raspuns final."""

    if contains_inappropriate_language(user_query):
        return build_inappropriate_language_response()

    intent = classify_user_query(user_query, chat_history=chat_history)

    if intent != "book_request":
        return build_non_book_response(intent)

    results = search_books(user_query)
    context = build_context(results)

    messages = build_messages(
        user_query=user_query,
        context=context,
        chat_history=chat_history,
    )

    first_response = client.chat.completions.create(
        model=OPENAI_CHAT_MODEL,
        messages=messages,
        tools=TOOLS,
        tool_choice={
            "type": "function",
            "function": {"name": "get_summary_by_title"},
        },
    )

    assistant_message = first_response.choices[0].message
    messages.append(assistant_message)

    tool_call = assistant_message.tool_calls[0]
    arguments = json.loads(tool_call.function.arguments)

    selected_title = arguments["title"]
    summary_text = get_summary_by_title(selected_title)

    messages.append(
        {
            "role": "tool",
            "tool_call_id": tool_call.id,
            "content": summary_text,
        }
    )

    final_response = client.chat.completions.create(
        model=OPENAI_CHAT_MODEL,
        messages=messages,
    )

    return {
        "answer": final_response.choices[0].message.content,
        "selected_title": selected_title,
        "summary": summary_text,
        "results": results,
    }