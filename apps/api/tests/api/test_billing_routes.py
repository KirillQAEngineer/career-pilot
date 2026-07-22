import hashlib
import hmac
import json

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.config import settings
from app.core.rate_limit import api_rate_limiter, auth_rate_limiter
from app.db.models.base import Base
from app.db.session import get_db
from app.main import app
from app.services.nowpayments import NowPaymentsClient


def build_client():
    auth_rate_limiter.clear()
    api_rate_limiter.clear()
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)

    def override_get_db():
        db = session_factory()

        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    return TestClient(app)


def register(client: TestClient) -> dict[str, str]:
    client.post(
        "/auth/register",
        json={
            "email": "buyer@example.com",
            "password": "strong-password",
            "full_name": "Analytics Buyer",
        },
    )
    login = client.post(
        "/auth/login",
        data={"username": "buyer@example.com", "password": "strong-password"},
    )

    return {"Authorization": f"Bearer {login.json()['access_token']}"}


def configure_nowpayments(monkeypatch) -> None:
    monkeypatch.setattr(settings, "nowpayments_api_key", "test-api-key")
    monkeypatch.setattr(settings, "nowpayments_ipn_secret", "test-ipn-secret")


def sign_ipn(payload: dict) -> str:
    canonical = json.dumps(payload, separators=(",", ":"), sort_keys=True)
    return hmac.new(
        settings.nowpayments_ipn_secret.encode(),
        canonical.encode(),
        hashlib.sha512,
    ).hexdigest()


def payment_payload(
    *,
    payment_id: str,
    invoice_id: str,
    order_id: str,
    amount: str = "1.25",
    status: str = "finished",
) -> dict:
    return {
        "payment_id": payment_id,
        "invoice_id": invoice_id,
        "payment_status": status,
        "price_amount": amount,
        "price_currency": "usd",
        "order_id": order_id,
    }


def test_verified_crypto_payment_grants_lifetime_access(monkeypatch):
    configure_nowpayments(monkeypatch)
    client = build_client()
    headers = register(client)

    locked = client.get("/applications", headers=headers)
    billing = client.get("/billing/me", headers=headers)

    assert locked.status_code == 403
    assert billing.status_code == 200
    assert billing.json()["price_minor_units"] == 125
    assert billing.json()["currency"] == "USD"
    assert billing.json()["display_price"] == "99 ₽"
    assert billing.json()["checkout_available"] is True
    assert billing.json()["has_analytics_access"] is False

    monkeypatch.setattr(
        NowPaymentsClient,
        "create_invoice",
        lambda self, payment, user: {
            "id": "invoice-1",
            "invoice_url": "https://nowpayments.test/invoice-1",
        },
    )
    checkout = client.post(
        "/billing/analytics-lifetime/checkout",
        headers=headers,
    )

    assert checkout.status_code == 200
    assert checkout.json()["confirmation_url"] == (
        "https://nowpayments.test/invoice-1"
    )

    provider_payload = payment_payload(
        payment_id="crypto-payment-1",
        invoice_id="invoice-1",
        order_id=checkout.json()["payment_id"],
    )
    monkeypatch.setattr(
        NowPaymentsClient,
        "get_payment",
        lambda self, provider_id: provider_payload,
    )
    webhook = client.post(
        "/billing/nowpayments/ipn",
        content=json.dumps(provider_payload),
        headers={
            "Content-Type": "application/json",
            "x-nowpayments-sig": sign_ipn(provider_payload),
        },
    )

    assert webhook.status_code == 204
    assert client.get("/billing/me", headers=headers).json()[
        "has_analytics_access"
    ] is True
    assert client.get("/applications", headers=headers).status_code == 200

    app.dependency_overrides.clear()


def test_payment_with_wrong_amount_never_grants_access(monkeypatch):
    configure_nowpayments(monkeypatch)
    client = build_client()
    headers = register(client)
    monkeypatch.setattr(
        NowPaymentsClient,
        "create_invoice",
        lambda self, payment, user: {
            "id": "invoice-2",
            "invoice_url": "https://nowpayments.test/invoice-2",
        },
    )
    checkout = client.post(
        "/billing/analytics-lifetime/checkout",
        headers=headers,
    )
    signed_payload = payment_payload(
        payment_id="crypto-payment-2",
        invoice_id="invoice-2",
        order_id=checkout.json()["payment_id"],
    )
    provider_payload = dict(signed_payload, price_amount="1.00")
    monkeypatch.setattr(
        NowPaymentsClient,
        "get_payment",
        lambda self, provider_id: provider_payload,
    )

    webhook = client.post(
        "/billing/nowpayments/ipn",
        content=json.dumps(signed_payload),
        headers={
            "Content-Type": "application/json",
            "x-nowpayments-sig": sign_ipn(signed_payload),
        },
    )

    assert webhook.status_code == 502
    assert client.get("/billing/me", headers=headers).json()[
        "has_analytics_access"
    ] is False

    app.dependency_overrides.clear()


def test_invalid_ipn_signature_is_rejected(monkeypatch):
    configure_nowpayments(monkeypatch)
    client = build_client()
    payload = payment_payload(
        payment_id="crypto-payment-3",
        invoice_id="invoice-3",
        order_id="unknown-order",
    )

    webhook = client.post(
        "/billing/nowpayments/ipn",
        json=payload,
        headers={"x-nowpayments-sig": "invalid"},
    )

    assert webhook.status_code == 401
    app.dependency_overrides.clear()
