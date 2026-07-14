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

def test_update_application_status():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    application = repository.create_from_interaction(
        user.id,
        application_data(),
    )

    updated = repository.update_status(
        user.id,
        application.id,
        "interview",
    )

    assert updated is not None
    assert updated.id == application.id
    assert updated.status == "interview"

    persisted = db.query(Application).filter(
        Application.id == application.id,
    ).first()

    assert persisted is not None
    assert persisted.status == "interview"

    db.close()


def test_update_application_status_returns_none_for_other_user():
    db = build_session()
    owner = create_user(db)

    other_user = User(
        email="other-application-user@example.com",
        hashed_password="test-password",
        full_name="Other Application User",
    )

    db.add(other_user)
    db.commit()
    db.refresh(other_user)

    repository = ApplicationRepository(db)

    application = repository.create_from_interaction(
        owner.id,
        application_data(),
    )

    updated = repository.update_status(
        other_user.id,
        application.id,
        "offer",
    )

    assert updated is None

    persisted = db.query(Application).filter(
        Application.id == application.id,
    ).first()

    assert persisted is not None
    assert persisted.status == "applied"

    db.close()


def test_update_application_status_returns_none_for_missing_application():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    updated = repository.update_status(
        user.id,
        999999,
        "rejected",
    )

    assert updated is None

    db.close()


def test_get_stats_returns_zero_counts_for_user_without_applications():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    result = repository.get_stats(user.id)

    assert result == {
        "total_applications": 0,
        "total_screenings": 0,
        "total_interviews": 0,
        "total_offers": 0,
        "total_rejected": 0,
        "active_processes": 0,
        "screening_in_progress": 0,
        "interview_in_progress": 0,
        "technical_interview_in_progress": 0,
        "offer_in_progress": 0,
        "interviews": 0,
        "offers": 0,
        "rejected": 0,
    }

    db.close()


def test_get_stats_aggregates_application_statuses():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    statuses = [
        "applied",
        "screening",
        "interview",
        "technical_interview",
        "offer",
        "rejected",
    ]

    for index, status in enumerate(statuses, start=1):
        data = application_data()
        data["job_external_id"] = str(index)
        data["job_url"] = f"https://example.com/jobs/{index}"

        application = repository.create_from_interaction(
            user.id,
            data,
        )

        repository.update_status(
            user.id,
            application.id,
            status,
        )

    result = repository.get_stats(user.id)

    assert result == {
        "total_applications": 6,
        "total_screenings": 1,
        "total_interviews": 2,
        "total_offers": 1,
        "total_rejected": 1,
        "active_processes": 4,
        "screening_in_progress": 1,
        "interview_in_progress": 1,
        "technical_interview_in_progress": 1,
        "offer_in_progress": 1,
        "interviews": 2,
        "offers": 1,
        "rejected": 1,
    }

    db.close()


def test_get_stats_only_counts_requested_user_applications():
    db = build_session()
    first_user = create_user(db)

    second_user = User(
        email="second-application-test@example.com",
        hashed_password="test-password",
        full_name="Second Application Test User",
    )

    db.add(second_user)
    db.commit()
    db.refresh(second_user)

    repository = ApplicationRepository(db)

    first_data = application_data()
    first_data["job_external_id"] = "first-user-job"

    repository.create_from_interaction(
        first_user.id,
        first_data,
    )

    second_data = application_data()
    second_data["job_external_id"] = "second-user-job"

    second_application = repository.create_from_interaction(
        second_user.id,
        second_data,
    )

    repository.update_status(
        second_user.id,
        second_application.id,
        "offer",
    )

    result = repository.get_stats(first_user.id)

    assert result == {
        "total_applications": 1,
        "total_screenings": 0,
        "total_interviews": 0,
        "total_offers": 0,
        "total_rejected": 0,
        "active_processes": 1,
        "screening_in_progress": 0,
        "interview_in_progress": 0,
        "technical_interview_in_progress": 0,
        "offer_in_progress": 0,
        "interviews": 0,
        "offers": 0,
        "rejected": 0,
    }

    db.close()


def test_analytics_adjustments_override_totals_but_not_in_progress_counts():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    application = repository.create_from_interaction(
        user.id,
        application_data(),
    )
    repository.update_status(user.id, application.id, "screening")

    repository.update_analytics_adjustment(
        user.id,
        {
            "total_applications": 12,
            "total_screenings": 8,
            "total_interviews": 5,
            "total_offers": 2,
            "total_rejected": 3,
        },
    )

    assert repository.get_stats(user.id) == {
        "total_applications": 12,
        "total_screenings": 8,
        "total_interviews": 5,
        "total_offers": 2,
        "total_rejected": 3,
        "active_processes": 1,
        "screening_in_progress": 1,
        "interview_in_progress": 0,
        "technical_interview_in_progress": 0,
        "offer_in_progress": 0,
        "interviews": 5,
        "offers": 2,
        "rejected": 3,
    }

    db.close()


def test_analytics_adjustments_can_be_cleared_to_restore_automatic_totals():
    db = build_session()
    user = create_user(db)

    repository = ApplicationRepository(db)

    repository.update_analytics_adjustment(
        user.id,
        {"total_applications": 10},
    )
    repository.update_analytics_adjustment(
        user.id,
        {"total_applications": None},
    )

    assert repository.get_stats(user.id)["total_applications"] == 0

    db.close()
