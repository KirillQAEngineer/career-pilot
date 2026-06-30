from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[4]
ENV_FILE = BASE_DIR / ".env"

class Settings(BaseSettings):
    app_name: str = "CareerPilot API"
    app_version: str = "0.1.0"
    debug: bool = True

    database_url: str

    secret_key: str

    openai_api_key: str = ""

    model_config = SettingsConfigDict(
    env_file=ENV_FILE,
    extra="ignore",
)


settings = Settings()