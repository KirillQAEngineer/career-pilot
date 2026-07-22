from datetime import UTC, datetime, timedelta
from hashlib import sha256

from sqlalchemy.orm import Session

from app.db.models.cached_job import CachedJob
from app.schemas.job import Job


def normalize_job_query(query: str) -> str:
    return " ".join(query.strip().casefold().split())[:255]


class CachedJobRepository:
    def __init__(self, db: Session):
        self.db = db

    def store(self, query: str, jobs: list[Job]) -> None:
        query_key = normalize_job_query(query)
        now = datetime.now(UTC).replace(tzinfo=None)
        existing_records = (
            self.db.query(CachedJob)
            .filter(CachedJob.query_key == query_key)
            .all()
        )
        existing_by_identity = {
            (item.source, item.external_id): item
            for item in existing_records
        }

        for job in jobs:
            external_id = job.external_id.strip() or self._fallback_id(job)
            cached = existing_by_identity.get((job.source, external_id))

            if cached is None:
                cached = CachedJob(
                    query_key=query_key,
                    source=job.source,
                    external_id=external_id,
                    title=job.title,
                    company=job.company,
                    location=job.location,
                    url=job.url,
                    description=job.description,
                    work_format=job.work_format,
                    published_at=job.published_at,
                    first_seen_at=now,
                    last_seen_at=now,
                )
                self.db.add(cached)
                existing_by_identity[(job.source, external_id)] = cached
            else:
                cached.title = job.title
                cached.company = job.company
                cached.location = job.location
                cached.url = job.url
                cached.description = job.description
                cached.work_format = job.work_format
                cached.published_at = job.published_at
                cached.last_seen_at = now

        self.db.commit()

    def get_recent(
        self,
        query: str,
        *,
        limit: int = 500,
        max_age_days: int = 14,
    ) -> list[Job]:
        query_key = normalize_job_query(query)
        cutoff = datetime.now(UTC).replace(tzinfo=None) - timedelta(
            days=max_age_days
        )
        records = (
            self.db.query(CachedJob)
            .filter(
                CachedJob.query_key == query_key,
                CachedJob.last_seen_at >= cutoff,
            )
            .order_by(CachedJob.last_seen_at.desc())
            .limit(limit)
            .all()
        )

        return [
            Job(
                title=item.title,
                company=item.company,
                location=item.location,
                url=item.url,
                source=item.source,
                external_id=item.external_id,
                description=item.description,
                work_format=item.work_format,
                published_at=item.published_at,
            )
            for item in records
        ]

    def _fallback_id(self, job: Job) -> str:
        value = "|".join([job.url, job.title, job.company])

        return sha256(value.encode("utf-8")).hexdigest()
