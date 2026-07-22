import re
import unicodedata

from app.schemas.job import Job


def normalize_job_fingerprint(value: str | None) -> str:
    normalized = unicodedata.normalize("NFKC", value or "").casefold()

    return " ".join(re.sub(r"[^\w]+", " ", normalized).split())


def job_deduplication_key(job: Job) -> str:
    title = normalize_job_fingerprint(job.title)
    company = normalize_job_fingerprint(job.company)

    if title and company:
        return f"role::{title}::{company}"

    source = normalize_job_fingerprint(job.source)
    external_id = normalize_job_fingerprint(job.external_id)

    if source and external_id:
        return f"provider::{source}::{external_id}"

    location = normalize_job_fingerprint(job.location)
    url = (job.url or "").strip().casefold()

    return f"fallback::{title}::{company}::{location}::{url}"


def deduplicate_jobs(jobs: list[Job]) -> list[Job]:
    unique: dict[str, Job] = {}

    for job in jobs:
        unique.setdefault(job_deduplication_key(job), job)

    return list(unique.values())
