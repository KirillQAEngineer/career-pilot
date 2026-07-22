from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.models.base import Base
from app.db.repositories.cached_job_repository import CachedJobRepository
from app.schemas.job import Job


def test_persistent_cache_keeps_large_unique_job_inventory():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)
    jobs = [
        Job(
            title=f"QA Engineer {index}",
            company="Acme",
            location="Remote",
            url=f"https://example.com/jobs/{index}",
            source="Example",
            external_id=str(index),
        )
        for index in range(250)
    ]

    with session_factory() as db:
        repository = CachedJobRepository(db)
        repository.store("QA Engineer", jobs)
        cached = repository.get_recent(" qa   engineer ")

    assert len(cached) == 250
    assert len({job.external_id for job in cached}) == 250


def test_persistent_cache_skips_same_role_repeated_for_multiple_locations():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)
    jobs = [
        Job(
            title="QA Engineering Lead (Automation Testing)",
            company="St. George Tanaq Corporation",
            location=location,
            url=f"https://example.com/jobs/{index}",
            source="Example",
            external_id=str(index),
        )
        for index, location in enumerate(["Bismarck", "Miami", "Boston"])
    ]

    with session_factory() as db:
        repository = CachedJobRepository(db)
        repository.store("QA Engineer", jobs)
        cached = repository.get_recent("QA Engineer")

    assert len(cached) == 1


def test_persistent_cache_deduplicates_same_role_across_refreshes():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)

    with session_factory() as db:
        repository = CachedJobRepository(db)
        repository.store(
            "QA Engineer",
            [
                Job(
                    title="QA Engineer",
                    company="Acme",
                    location="Boston",
                    url="https://example.com/jobs/1",
                    source="Adzuna",
                    external_id="1",
                )
            ],
        )
        repository.store(
            "QA Engineer",
            [
                Job(
                    title="QA Engineer",
                    company="Acme",
                    location="Miami",
                    url="https://example.com/jobs/2",
                    source="Adzuna",
                    external_id="2",
                )
            ],
        )
        cached = repository.get_recent("QA Engineer")

    assert len(cached) == 1
    assert cached[0].external_id == "1"
    assert cached[0].url == "https://example.com/jobs/1"
