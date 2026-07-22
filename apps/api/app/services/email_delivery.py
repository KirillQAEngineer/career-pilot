from html import escape

import requests

from app.core.config import settings


class EmailDeliveryUnavailable(RuntimeError):
    pass


class EmailDeliveryService:
    URL = "https://api.brevo.com/v3/smtp/email"

    @property
    def is_configured(self) -> bool:
        if settings.environment == "test":
            return True

        return bool(
            settings.email_delivery_provider == "brevo"
            and settings.brevo_api_key
            and settings.email_from_address
        )

    def send_verification_email(
        self,
        *,
        recipient: str,
        full_name: str,
        verification_url: str,
        idempotency_key: str,
    ) -> None:
        if settings.environment == "test":
            return

        if not self.is_configured:
            raise EmailDeliveryUnavailable(
                "Email delivery is not configured"
            )

        safe_name = escape(full_name)
        safe_url = escape(verification_url, quote=True)
        response = requests.post(
            self.URL,
            headers={
                "accept": "application/json",
                "api-key": settings.brevo_api_key,
                "content-type": "application/json",
            },
            json={
                "sender": {
                    "name": settings.email_from_name,
                    "email": settings.email_from_address,
                },
                "to": [{"email": recipient, "name": full_name}],
                "subject": "Подтвердите почту в JobCompass",
                "htmlContent": (
                    "<!doctype html><html><body>"
                    f"<p>Здравствуйте, {safe_name}!</p>"
                    "<p>Подтвердите адрес электронной почты для JobCompass.</p>"
                    f'<p><a href="{safe_url}">Подтвердить почту</a></p>'
                    "<p>Ссылка действует ограниченное время. "
                    "Если вы не создавали аккаунт, просто проигнорируйте письмо.</p>"
                    "</body></html>"
                ),
                "textContent": (
                    "Подтвердите адрес электронной почты для JobCompass: "
                    f"{verification_url}"
                ),
                "headers": {"Idempotency-Key": idempotency_key},
                "tags": ["email-verification"],
            },
            timeout=8,
        )
        response.raise_for_status()
