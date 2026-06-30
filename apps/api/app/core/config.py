from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path

class Settings(BaseSettings):
    app_name: str = "CareerPilot API"
    app_version: str = "0.1.0"
    debug: bool = True

    database_url: str

    database_url_docker: str = ""

    access_token_expire_minutes: int = 1440

    secret_key: str

    gemini_api_key: str = ""

    model_config = SettingsConfigDict(
    env_file=".env",
    extra="ignore",
)


settings = Settings()