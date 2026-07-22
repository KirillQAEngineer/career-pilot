from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.rate_limit import auth_rate_limiter

from app.db.models.base import Base
from app.db.session import get_db
from app.main import app


def build_client():
    auth_rate_limiter.clear()
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
            "email": "profile@example.com",
            "password": "strong-password",
            "full_name": "Profile User",
        },
    )

    response = client.post(
        "/auth/login",
        data={"username": "profile@example.com", "password": "strong-password"},
    )

    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_user_can_create_profile_without_resume():
    client = build_client()
    headers = register(client)

    response = client.put(
        "/profile/me",
        headers=headers,
        json={
            "profession": "QA Engineer",
            "level": "Middle",
            "skills": ["API Testing", "SQL"],
            "technologies": ["Postman"],
            "english_level": "B2",
            "preferred_roles": ["QA Engineer"],
        },
    )

    assert response.status_code == 200
    assert response.json()["resume_text"] == ""
    assert response.json()["skills"] == "API Testing,SQL"

    loaded = client.get("/profile/me", headers=headers)

    assert loaded.status_code == 200
    assert loaded.json()["profession"] == "QA Engineer"

    app.dependency_overrides.clear()


def test_deleting_resume_preserves_manual_profile_fields():
    client = build_client()
    headers = register(client)
    payload = {
        "profession": "QA Engineer",
        "level": "Senior",
        "skills": ["Testing"],
        "technologies": ["Postman"],
        "english_level": "B2",
        "preferred_roles": ["Senior QA Engineer"],
    }

    client.put("/profile/me", headers=headers, json=payload)
    response = client.delete("/profile/me/resume", headers=headers)

    assert response.status_code == 200
    assert response.json()["profession"] == "QA Engineer"
    assert response.json()["resume_text"] == ""

    app.dependency_overrides.clear()
