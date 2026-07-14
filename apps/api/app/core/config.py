from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "JobCompass API"
    app_version: str = "0.1.0"
    debug: bool = True

    database_url: str

    database_url_docker: str = ""

    access_token_expire_minutes: int = 1440

    secret_key: str

    gemini_api_key: str = ""
    
    adzuna_app_id: str = ""
    
    adzuna_app_key: str = ""

    upload_dir: str = "uploads"

    jooble_api_key: str = ""

    backend_cors_origins: str = (
        "http://localhost,"
        "http://127.0.0.1,"
        "https://kirillqaengineer.github.io"
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )


settings = Settings()
