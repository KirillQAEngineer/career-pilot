from urllib.parse import parse_qs, urlparse

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.models.base import Base
from app.db.repositories.user_repository import UserRepository
from app.services.email_verification import EmailVerificationService


ORIGINAL_SEND = EmailVerificationService.send


class FakeDelivery:
    is_configured = True

    def __init__(self):
        self.verification_url = None

    def send_verification_email(self, **payload):
        self.verification_url = payload["verification_url"]


def test_verification_token_is_one_time_and_only_hash_is_stored(monkeypatch):
    monkeypatch.setattr(EmailVerificationService, "send", ORIGINAL_SEND)
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)

    with session_factory() as db:
        repository = UserRepository(db)
        user = repository.create(
            email="verify@example.com",
            password="strong-password",
            full_name="Verify User",
        )
        delivery = FakeDelivery()
        service = EmailVerificationService(repository, delivery=delivery)

        service.send(user)

        token = parse_qs(urlparse(delivery.verification_url).query)["token"][0]
        assert token not in user.email_verification_token_hash
        assert service.verify(token) is not None
        assert user.email_verified_at is not None
        assert user.email_verification_required is False
        assert service.verify(token) is None
