from datetime import UTC, datetime, timedelta
from hashlib import sha256
from secrets import token_urlsafe
from urllib.parse import urlencode

from app.core.config import settings
from app.db.models.user import User
from app.db.repositories.user_repository import UserRepository
from app.services.email_delivery import EmailDeliveryService


def hash_verification_token(token: str) -> str:
    return sha256(token.encode("utf-8")).hexdigest()


class EmailVerificationService:
    def __init__(
        self,
        repository: UserRepository,
        delivery: EmailDeliveryService | None = None,
    ) -> None:
        self.repository = repository
        self.delivery = delivery or EmailDeliveryService()

    def ensure_available(self) -> None:
        if not self.delivery.is_configured:
            raise RuntimeError("Email delivery is not configured")

    def send(self, user: User) -> None:
        self.ensure_available()
        token = token_urlsafe(32)
        now = datetime.now(UTC).replace(tzinfo=None)
        expires_at = now + timedelta(
            hours=settings.email_verification_ttl_hours
        )
        token_hash = hash_verification_token(token)
        self.repository.set_verification_token(
            user,
            token_hash=token_hash,
            expires_at=expires_at,
            sent_at=now,
        )
        query = urlencode({"token": token})
        verification_url = (
            f"{settings.public_api_base_url.rstrip('/')}"
            f"/auth/verify-email?{query}"
        )
        self.delivery.send_verification_email(
            recipient=user.email,
            full_name=user.full_name,
            verification_url=verification_url,
            idempotency_key=token_hash,
        )

    def verify(self, token: str) -> User | None:
        token_hash = hash_verification_token(token)
        user = self.repository.get_by_verification_token_hash(token_hash)

        if user is None or user.email_verification_expires_at is None:
            return None

        now = datetime.now(UTC).replace(tzinfo=None)

        if user.email_verification_expires_at < now:
            return None

        return self.repository.mark_email_verified(user, now)
