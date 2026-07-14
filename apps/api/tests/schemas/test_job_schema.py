from app.schemas.job import Job


def test_job_is_backward_compatible_without_optional_metadata():
    job = Job(
        title="QA Engineer",
        company="JobCompass",
        location="Remote",
        url="https://example.com/jobs/1",
        source="TestProvider",
        external_id="1",
    )

    assert job.work_format is None
    assert job.published_at is None


def test_job_accepts_optional_metadata():
    job = Job(
        title="Senior QA Engineer",
        company="JobCompass",
        location="Berlin",
        url="https://example.com/jobs/2",
        source="TestProvider",
        external_id="2",
        work_format="Hybrid",
        published_at="2026-07-10T12:00:00Z",
    )

    assert job.work_format == "Hybrid"
    assert job.published_at == "2026-07-10T12:00:00Z"
