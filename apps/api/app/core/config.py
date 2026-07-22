from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import model_validator
from typing import Literal, Self


class Settings(BaseSettings):
    app_name: str = "JobCompass API"
    app_version: str = "0.1.0"
    environment: Literal["development", "test", "production"] = "development"
    debug: bool = False

    database_url: str

    database_url_docker: str = ""

    access_token_expire_minutes: int = 1440

    secret_key: str

    gemini_api_key: str = ""

    adzuna_app_id: str = ""

    adzuna_app_key: str = ""

    upload_dir: str = "uploads"
    max_resume_upload_bytes: int = 5 * 1024 * 1024

    jooble_api_key: str = ""

    backend_cors_origins: str = (
        "http://localhost,"
        "http://127.0.0.1,"
        "https://kirillqaengineer.github.io"
    )

    backend_allowed_hosts: str = (
        "localhost,127.0.0.1,testserver,jobcompass-api.onrender.com"
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )

    @model_validator(mode="after")
    def validate_production_secret(self) -> Self:
        if self.environment == "production" and len(self.secret_key) < 32:
            raise ValueError(
                "SECRET_KEY must contain at least 32 characters in production"
            )

        return self


settings = Settings()
