from src.utils.tools import get_summary_by_title


def test_get_summary_by_title_returns_summary_for_existing_title():
    summary = get_summary_by_title("1984")

    assert isinstance(summary, str)
    assert "Big Brother" in summary


def test_get_summary_by_title_returns_message_for_missing_title():
    result = get_summary_by_title("Carte care nu exista")

    assert result == "Nu am gasit un rezumat pentru titlul: Carte care nu exista"