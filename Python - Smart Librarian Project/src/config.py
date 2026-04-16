import os
from dotenv import load_dotenv

load_dotenv()

def get_env_variable(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise ValueError(f"{name} is not set in .env")
    return value

OPENAI_API_KEY = get_env_variable("OPENAI_API_KEY")
OPENAI_EMBEDDING_MODEL = get_env_variable("OPENAI_EMBEDDING_MODEL")
OPENAI_CHAT_MODEL = get_env_variable("OPENAI_CHAT_MODEL")

APP_DEFAULT_LANGUAGE = os.getenv("APP_DEFAULT_LANGUAGE", "ro")