from src.utils.conversation_control import (
    normalize_text,
    contains_inappropriate_language,
    build_inappropriate_language_response,
    build_non_book_response,
)


def test_normalize_text_lowercases_and_removes_punctuation():
    result = normalize_text("Salut, IDIOT!!!")

    assert result == "salut idiot"


def test_contains_inappropriate_language_detects_blocked_word():
    result = contains_inappropriate_language("Esti idiot!")

    assert result is True


def test_contains_inappropriate_language_returns_false_for_clean_text():
    result = contains_inappropriate_language("Vreau o carte despre razboi.")

    assert result is False


def test_build_inappropriate_language_response_returns_expected_structure():
    result = build_inappropriate_language_response()

    assert result["selected_title"] is None
    assert result["summary"] is None
    assert result["results"] == {}
    assert "limbaj respectuos" in result["answer"]


def test_build_non_book_response_for_small_talk():
    result = build_non_book_response("small_talk")

    assert result["selected_title"] is None
    assert result["summary"] is None
    assert result["results"] == {}
    assert "recomandari de carti" in result["answer"]


def test_build_non_book_response_for_unsupported():
    result = build_non_book_response("unsupported")

    assert result["selected_title"] is None
    assert result["summary"] is None
    assert result["results"] == {}
    assert "Nu te pot ajuta" in result["answer"]


def test_build_non_book_response_for_unclear():
    result = build_non_book_response("unclear")

    assert result["selected_title"] is None
    assert result["summary"] is None
    assert result["results"] == {}
    assert "Nu sunt sigur ce cauti" in result["answer"]