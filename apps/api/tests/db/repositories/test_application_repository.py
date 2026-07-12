from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.models.application import Application
from app.db.models.base import Base
from app.db.models.user import User
from app.db.repositories.application_repository import (
    ApplicationRepository,
)


def build_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    Base.metadata.create_all(engine)

    session_factory = sessionmaker(bind=engine)

    return session_factory()


def create_user(db):
    user = User(
        email="application-test@example.com",
        hashed_password="test-password",
        full_name="Application Test User",
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return user


def application_data():
    return {
        "job_title": "Senior QA Engineer",
        "job_company": "Acme",
        "job_url": "https://example.com/jobs/123",
        "job_location": "Berlin",
        "job_work_format": "Hybrid",
        "job_published_at": "2026-07-10T10:00:00Z",
        "job_source": "adzuna",
        "job_external_id": "123",
    }


def test_create_application_from_interaction():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    application = repository.create_from_interaction(
        user.id,
        application_data(),
    )

    assert application.id is not None
    assert application.user_id == user.id
    assert application.status == "applied"
    assert application.job_source == "adzuna"
    assert application.job_external_id == "123"

    db.close()


def test_create_application_is_idempotent():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    first = repository.create_from_interaction(
        user.id,
        application_data(),
    )

    second = repository.create_from_interaction(
        user.id,
        application_data(),
    )

    applications = db.query(Application).all()

    assert first.id == second.id
    assert len(applications) == 1

    db.close()


def test_get_applications_by_user_id():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    repository.create_from_interaction(
        user.id,
        application_data(),
    )

    applications = repository.get_by_user_id(user.id)

    assert len(applications) == 1
    assert applications[0].job_title == "Senior QA Engineer"

    db.close()
