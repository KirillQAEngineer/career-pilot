from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

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
