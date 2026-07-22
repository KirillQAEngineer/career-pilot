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

    public_api_base_url: str = "http://127.0.0.1:8000"
    frontend_base_url: str = "http://localhost:5123"

    email_delivery_provider: Literal["disabled", "brevo"] = "disabled"
    brevo_api_key: str = ""
    email_from_address: str = ""
    email_from_name: str = "JobCompass"
    email_verification_ttl_hours: int = 24

    nowpayments_api_key: str = ""
    nowpayments_ipn_secret: str = ""
    analytics_lifetime_price_minor_units: int = 125
    analytics_lifetime_price_currency: str = "USD"
    analytics_lifetime_display_price: str = "99 ₽"

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

        if self.analytics_lifetime_price_minor_units <= 0:
            raise ValueError("Analytics lifetime price must be positive")

        if len(self.analytics_lifetime_price_currency.strip()) not in range(3, 17):
            raise ValueError("Analytics lifetime currency is invalid")

        return self


settings = Settings()
