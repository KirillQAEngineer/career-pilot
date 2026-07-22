from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from uuid import UUID

from app.core.rate_limit import auth_rate_limiter
from app.db.models.base import Base
from app.db.session import get_db
from app.main import app


def build_session_factory():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    Base.metadata.create_all(engine)

    return sessionmaker(bind=engine)


def build_client():
    auth_rate_limiter.clear()
    session_factory = build_session_factory()

    def override_get_db():
        db = session_factory()

        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    return TestClient(app)


def test_register_creates_user_and_returns_token():
    client = build_client()

    response = client.post(
        "/auth/register",
        json={
            "email": "New.User@Example.com",
            "password": "strong-password",
            "full_name": "New User",
        },
    )

    assert response.status_code == 201
    assert response.json()["token_type"] == "bearer"
    assert response.json()["access_token"]

    app.dependency_overrides.clear()


def test_register_rejects_duplicate_email():
    client = build_client()
    payload = {
        "email": "duplicate@example.com",
        "password": "strong-password",
        "full_name": "Duplicate User",
    }

    first = client.post("/auth/register", json=payload)
    second = client.post("/auth/register", json=payload)

    assert first.status_code == 201
    assert second.status_code == 409

    app.dependency_overrides.clear()


def test_registered_user_can_login():
    client = build_client()

    client.post(
        "/auth/register",
        json={
            "email": "login@example.com",
            "password": "strong-password",
            "full_name": "Login User",
        },
    )

    response = client.post(
        "/auth/login",
        data={
            "username": "login@example.com",
            "password": "strong-password",
        },
    )

    assert response.status_code == 200
    assert response.json()["token_type"] == "bearer"
    assert response.json()["access_token"]

    app.dependency_overrides.clear()


def test_registration_rejects_weak_password():
    client = build_client()

    response = client.post(
        "/auth/register",
        json={
            "email": "weak@example.com",
            "password": "short123",
            "full_name": "Weak Password",
        },
    )

    assert response.status_code == 422

    app.dependency_overrides.clear()


def test_login_is_rate_limited_per_account():
    client = build_client()
    client.post(
        "/auth/register",
        json={
            "email": "limited@example.com",
            "password": "strong-password",
            "full_name": "Rate Limited",
        },
    )

    for _ in range(5):
        response = client.post(
            "/auth/login",
            data={"username": "limited@example.com", "password": "wrong"},
        )
        assert response.status_code == 401

    response = client.post(
        "/auth/login",
        data={"username": "limited@example.com", "password": "wrong"},
    )

    assert response.status_code == 429
    assert int(response.headers["Retry-After"]) > 0

    app.dependency_overrides.clear()


def test_account_uses_public_uuid_and_rejects_legacy_numeric_subject():
    client = build_client()
    registration = client.post(
        "/auth/register",
        json={
            "email": "uuid@example.com",
            "password": "strong-password",
            "full_name": "UUID User",
        },
    )
    token = registration.json()["access_token"]

    account = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    invalid = client.get(
        "/auth/me",
        headers={"Authorization": "Bearer invalid-token"},
    )

    assert account.status_code == 200
    assert UUID(account.json()["id"])
    assert invalid.status_code == 401

    app.dependency_overrides.clear()


def test_api_returns_security_headers():
    client = build_client()

    response = client.get("/")

    assert response.headers["Cache-Control"] == "no-store"
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Content-Security-Policy"] == "frame-ancestors 'none'"

    app.dependency_overrides.clear()
