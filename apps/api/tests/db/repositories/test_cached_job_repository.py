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
