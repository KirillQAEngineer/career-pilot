from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.rate_limit import api_rate_limiter, auth_rate_limiter
from app.db.models.base import Base
from app.db.models.user import User
from app.db.session import get_db
from app.main import app


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

    return TestClient(app), session_factory


def register(client: TestClient, session_factory, email: str) -> dict[str, str]:
    client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "strong-password",
            "full_name": email.split("@", 1)[0],
        },
    )

    with session_factory() as db:
        user = db.query(User).filter(User.email == email).one()
        user.analytics_lifetime_access = True
        db.commit()

    response = client.post(
        "/auth/login",
        data={"username": email, "password": "strong-password"},
    )

    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_protected_endpoints_reject_missing_and_malformed_tokens():
    client, _ = build_client()

    for endpoint in ["/auth/me", "/profile/me", "/applications", "/admin/users"]:
        missing = client.get(endpoint)
        malformed = client.get(
            endpoint,
            headers={"Authorization": "Bearer malformed"},
        )

        assert missing.status_code == 401
        assert malformed.status_code == 401

    app.dependency_overrides.clear()


def test_untrusted_host_and_cross_origin_preflight_are_rejected():
    client, _ = build_client()

    untrusted_host = client.get("/", headers={"Host": "attacker.example"})
    untrusted_origin = client.options(
        "/auth/login",
        headers={
            "Origin": "https://attacker.example",
            "Access-Control-Request-Method": "POST",
        },
    )

    assert untrusted_host.status_code == 400
    assert untrusted_origin.status_code == 400
    assert "access-control-allow-origin" not in untrusted_origin.headers

    app.dependency_overrides.clear()


def test_user_cannot_modify_another_users_application():
    client, session_factory = build_client()
    first_user = register(client, session_factory, "first@example.com")
    second_user = register(client, session_factory, "second@example.com")
    created = client.post(
        "/applications",
        headers=first_user,
        json={
            "job_title": "QA Engineer",
            "job_company": "Acme",
            "job_url": "https://example.com/jobs/qa",
            "job_source": "example",
            "job_external_id": "qa-1",
        },
    )

    response = client.patch(
        f"/applications/{created.json()['id']}/status",
        headers=second_user,
        json={"status": "offer"},
    )

    assert created.status_code == 200
    assert "user_id" not in created.json()
    assert response.status_code == 404

    app.dependency_overrides.clear()


def test_saved_job_response_does_not_expose_internal_user_id():
    client, session_factory = build_client()
    headers = register(client, session_factory, "saved@example.com")
    interaction = client.post(
        "/jobs/interact",
        headers=headers,
        json={
            "job_title": "QA Engineer",
            "job_company": "Acme",
            "job_url": "https://example.com/jobs/qa",
            "job_source": "example",
            "job_external_id": "qa-1",
            "action": "like",
        },
    )
    saved = client.get("/jobs/saved", headers=headers)

    assert interaction.status_code == 200
    assert saved.status_code == 200
    assert "user_id" not in interaction.json()
    assert all("user_id" not in job for job in saved.json())

    app.dependency_overrides.clear()
