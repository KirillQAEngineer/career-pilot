from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from uuid import UUID

from app.core.rate_limit import auth_rate_limiter
from app.db.models.base import Base
from app.db.models.user import User
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

    return TestClient(app), session_factory


def register(client: TestClient, email: str) -> str:
    response = client.post(
        "/auth/register",
        json={
            "email": email,
            "password": "strong-password",
            "full_name": email.split("@", 1)[0],
        },
    )

    return response.json()["access_token"]


def authorize(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_non_admin_cannot_access_admin_data():
    client, _ = build_client()
    token = register(client, "user@example.com")

    response = client.get("/admin/users", headers=authorize(token))

    assert response.status_code == 403

    app.dependency_overrides.clear()


def test_admin_can_view_users_and_manage_roles():
    client, session_factory = build_client()
    admin_token = register(client, "admin@example.com")
    register(client, "member@example.com")

    with session_factory() as db:
        admin = db.query(User).filter(User.email == "admin@example.com").one()
        admin.is_admin = True
        db.commit()

    stats = client.get("/admin/stats", headers=authorize(admin_token))
    users = client.get("/admin/users", headers=authorize(admin_token))

    assert stats.status_code == 200
    assert stats.json() == {"total_users": 2, "total_admins": 1}
    assert users.status_code == 200
    assert len(users.json()) == 2

    member = next(
        user for user in users.json() if user["email"] == "member@example.com"
    )
    detail = client.get(
        f"/admin/users/{member['id']}",
        headers=authorize(admin_token),
    )
    promoted = client.patch(
        f"/admin/users/{member['id']}/role",
        headers=authorize(admin_token),
        json={"is_admin": True},
    )

    assert detail.status_code == 200
    assert detail.json()["profile"] is None
    assert promoted.status_code == 200
    assert promoted.json()["is_admin"] is True

    app.dependency_overrides.clear()


def test_admin_cannot_remove_own_role():
    client, session_factory = build_client()
    admin_token = register(client, "admin@example.com")

    with session_factory() as db:
        admin = db.query(User).filter(User.email == "admin@example.com").one()
        admin.is_admin = True
        admin_id = admin.public_id
        db.commit()

    response = client.patch(
        f"/admin/users/{admin_id}/role",
        headers=authorize(admin_token),
        json={"is_admin": False},
    )

    assert response.status_code == 400

    app.dependency_overrides.clear()


def test_current_account_returns_database_identity_and_role():
    client, _ = build_client()
    token = register(client, "account@example.com")

    response = client.get("/auth/me", headers=authorize(token))

    assert response.status_code == 200
    assert UUID(response.json()["id"])
    assert response.json()["email"] == "account@example.com"
    assert response.json()["is_admin"] is False

    app.dependency_overrides.clear()
