from unittest.mock import MagicMock

from app.db.models.job_interaction import JobInteraction
from app.db.repositories.job_interaction_repository import (
    JobInteractionRepository,
)


def make_data() -> dict:
    return {
        "job_title": "Senior QA Engineer",
        "job_company": "JobCompass",
        "job_url": "https://example.com/jobs/1",
        "job_location": "Berlin",
        "job_work_format": "Hybrid",
        "job_published_at": "2026-07-10T10:00:00Z",
        "job_source": "TestProvider",
        "job_external_id": "1",
        "action": "like",
    }


def make_db(existing_interactions=None):
    db = MagicMock()

    query = db.query.return_value
    filtered = query.filter.return_value
    filtered.all.return_value = existing_interactions or []

    return db


def test_create_saves_job_metadata() -> None:
    db = make_db()

    repository = JobInteractionRepository(db)

    result = repository.create(
        user_id=1,
        data=make_data(),
    )

    assert result.job_location == "Berlin"
    assert result.job_work_format == "Hybrid"
    assert (
        result.job_published_at
        == "2026-07-10T10:00:00Z"
    )

    db.add.assert_called_once_with(result)
    db.commit.assert_called_once()
    db.refresh.assert_called_once_with(result)


def test_existing_interaction_gets_missing_metadata() -> None:
    existing = JobInteraction(
        user_id=1,
        job_title="Senior QA Engineer",
        job_company="JobCompass",
        job_url="https://example.com/jobs/1",
        job_source="TestProvider",
        job_external_id="1",
        action="like",
    )

    db = make_db([existing])

    repository = JobInteractionRepository(db)

    result = repository.create(
        user_id=1,
        data=make_data(),
    )

    assert result is existing
    assert result.job_location == "Berlin"
    assert result.job_work_format == "Hybrid"
    assert (
        result.job_published_at
        == "2026-07-10T10:00:00Z"
    )

    db.add.assert_not_called()
    db.commit.assert_called_once()
    db.refresh.assert_called_once_with(existing)


def test_existing_metadata_is_not_overwritten() -> None:
    existing = JobInteraction(
        user_id=1,
        job_title="Senior QA Engineer",
        job_company="JobCompass",
        job_url="https://example.com/jobs/1",
        job_location="London",
        job_work_format="Remote",
        job_published_at="2026-07-09T10:00:00Z",
        job_source="TestProvider",
        job_external_id="1",
        action="like",
    )

    db = make_db([existing])

    repository = JobInteractionRepository(db)

    result = repository.create(
        user_id=1,
        data=make_data(),
    )

    assert result is existing
    assert result.job_location == "London"
    assert result.job_work_format == "Remote"
    assert (
        result.job_published_at
        == "2026-07-09T10:00:00Z"
    )

    db.commit.assert_not_called()
    db.refresh.assert_not_called()
