import base64
from typing import Any

from src.clients.openai_client import client


def build_book_image_prompt(title: str, summary: str | None = None) -> str:
    """Construieste promptul pentru generarea imaginii unei carti."""
    prompt = (
        f"Creeaza o ilustratie artistica pentru cartea '{title}'. "
        "Imaginea trebuie sa fie cinematica, sugestiva si potrivita cu atmosfera cartii. "
        "Nu include text pe imagine si nu include coperta exacta a cartii."
    )

    if summary:
        prompt += f" Rezumatul cartii este: {summary}"

    return prompt


def generate_book_image(title: str, summary: str | None = None) -> dict[str, Any]:
    """Genereaza o imagine pe baza cartii recomandate."""
    prompt = build_book_image_prompt(title=title, summary=summary)

    response = client.images.generate(
        model="gpt-image-1",
        prompt=prompt,
        size="1024x1024",
    )

    image_base64 = response.data[0].b64_json
    image_bytes = base64.b64decode(image_base64)

    return {
        "prompt": prompt,
        "image_bytes": image_bytes,
    }