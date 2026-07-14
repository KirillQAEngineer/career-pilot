from app.schemas.job import Job
from app.services.jobs.metadata_normalizer import (
    JobMetadataNormalizer,
)


def make_job(
    title="QA Engineer",
    location="Berlin",
    work_format=None,
    published_at=None,
):
    return Job(
        title=title,
        company="JobCompass",
        location=location,
        url="https://example.com/job",
        source="TestProvider",
        external_id="1",
        work_format=work_format,
        published_at=published_at,
    )


def test_detects_remote_from_explicit_work_format():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        work_format="remote",
    )

    result = normalizer.normalize_job(job)

    assert result.work_format == "Remote"


def test_detects_remote_from_location():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        location="Remote - Europe",
    )

    result = normalizer.normalize_job(job)

    assert result.work_format == "Remote"


def test_detects_hybrid_from_title():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        title="Senior QA Engineer (Hybrid)",
    )

    result = normalizer.normalize_job(job)

    assert result.work_format == "Hybrid"


def test_hybrid_has_priority_over_remote():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        title="Hybrid QA Engineer",
        location="Remote",
    )

    result = normalizer.normalize_job(job)

    assert result.work_format == "Hybrid"


def test_detects_onsite_from_title():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        title="On-site QA Engineer",
    )

    result = normalizer.normalize_job(job)

    assert result.work_format == "On-site"


def test_unknown_work_format_remains_none():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        location="Berlin",
    )

    result = normalizer.normalize_job(job)

    assert result.work_format is None


def test_normalizes_iso_date_to_utc():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        published_at="2026-07-10T12:00:00+02:00",
    )

    result = normalizer.normalize_job(job)

    assert result.published_at == "2026-07-10T10:00:00Z"


def test_normalizes_iso_date_with_z_suffix():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        published_at="2026-07-10T10:00:00Z",
    )

    result = normalizer.normalize_job(job)

    assert result.published_at == "2026-07-10T10:00:00Z"


def test_normalizes_unix_timestamp():
    normalizer = JobMetadataNormalizer()

    result = normalizer.normalize_published_at(
        1783677600,
    )

    assert result == "2026-07-10T10:00:00Z"


def test_normalizes_unix_timestamp_string():
    normalizer = JobMetadataNormalizer()

    result = normalizer.normalize_published_at(
        "1783677600",
    )

    assert result == "2026-07-10T10:00:00Z"


def test_normalizes_unix_timestamp_milliseconds():
    normalizer = JobMetadataNormalizer()

    result = normalizer.normalize_published_at(
        1783677600000,
    )

    assert result == "2026-07-10T10:00:00Z"


def test_normalizes_rss_pub_date():
    normalizer = JobMetadataNormalizer()

    result = normalizer.normalize_published_at(
        "Tue, 14 Jul 2026 03:03:10 +0000",
    )

    assert result == "2026-07-14T03:03:10Z"


def test_invalid_date_becomes_none():
    normalizer = JobMetadataNormalizer()

    job = make_job(
        published_at="not-a-date",
    )

    result = normalizer.normalize_job(job)

    assert result.published_at is None
