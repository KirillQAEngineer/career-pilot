import os
from datetime import UTC, datetime


os.environ["ENVIRONMENT"] = "test"
os.environ["SECRET_KEY"] = "test-only-secret-key-with-at-least-32-characters"

import pytest


@pytest.fixture(autouse=True)
def verify_registration_emails_in_legacy_tests(monkeypatch):
    """Keep old route tests focused; auth tests cover confirmation itself."""
    from app.services.email_verification import EmailVerificationService

    def mark_verified(service, user):
        service.repository.mark_email_verified(
            user,
            datetime.now(UTC).replace(tzinfo=None),
        )

    monkeypatch.setattr(EmailVerificationService, "send", mark_verified)
