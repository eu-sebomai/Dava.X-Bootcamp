from types import SimpleNamespace

from src.services.chatbot import run_chatbot


def test_run_chatbot_returns_inappropriate_language_response(monkeypatch):
    monkeypatch.setattr(
        "src.services.chatbot.contains_inappropriate_language",
        lambda user_query: True,
    )

    result = run_chatbot("Esti idiot")

    assert result["selected_title"] is None
    assert result["summary"] is None
    assert result["results"] == {}
    assert "limbaj respectuos" in result["answer"]


def test_run_chatbot_returns_non_book_response(monkeypatch):
    monkeypatch.setattr(
        "src.services.chatbot.contains_inappropriate_language",
        lambda user_query: False,
    )
    monkeypatch.setattr(
        "src.services.chatbot.classify_user_query",
        lambda user_query, chat_history=None: "small_talk",
    )

    result = run_chatbot("Buna")

    assert result["selected_title"] is None
    assert result["summary"] is None
    assert result["results"] == {}
    assert "recomandari de carti" in result["answer"]


def test_run_chatbot_returns_book_recommendation(monkeypatch):
    fake_results = {
        "documents": [[
            "Titlu: 1984\nAutor: George Orwell\nTeme: libertate, control social\nRezumat: test"
        ]],
        "metadatas": [[
            {
                "title": "1984",
                "author": "George Orwell",
                "themes": "libertate, control social",
            }
        ]],
        "distances": [[0.12]],
    }

    monkeypatch.setattr(
        "src.services.chatbot.contains_inappropriate_language",
        lambda user_query: False,
    )
    monkeypatch.setattr(
        "src.services.chatbot.classify_user_query",
        lambda user_query, chat_history=None: "book_request",
    )
    monkeypatch.setattr(
        "src.services.chatbot.search_books",
        lambda user_query: fake_results,
    )
    monkeypatch.setattr(
        "src.services.chatbot.get_summary_by_title",
        lambda title: "Rezumat complet pentru 1984",
    )

    first_message = SimpleNamespace(
        tool_calls=[
            SimpleNamespace(
                id="tool_1",
                function=SimpleNamespace(
                    name="get_summary_by_title",
                    arguments='{"title": "1984"}',
                ),
            )
        ]
    )

    second_message = SimpleNamespace(
        content="1) Recomandare: 1984\n2) De ce se potriveste\n3) Rezumat complet"
    )

    responses = [
        SimpleNamespace(
            choices=[SimpleNamespace(message=first_message)]
        ),
        SimpleNamespace(
            choices=[SimpleNamespace(message=second_message)]
        ),
    ]

    def fake_create(*args, **kwargs):
        return responses.pop(0)

    monkeypatch.setattr(
        "src.services.chatbot.client.chat.completions.create",
        fake_create,
    )

    result = run_chatbot("Vreau o carte despre libertate si control social")

    assert result["selected_title"] == "1984"
    assert result["summary"] == "Rezumat complet pentru 1984"
    assert result["results"] == fake_results
    assert "Recomandare" in result["answer"]