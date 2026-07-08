import pytest

from app.schemas.job import Job
from app.services.jobs.quality_pipeline import JobQualityPipeline


@pytest.fixture
def pipeline() -> JobQualityPipeline:
    return JobQualityPipeline()


def make_job(
    title: str,
    company: str = "Test Company",
    location: str = "Remote",
    source: str = "TestProvider",
    external_id: str = "1",
) -> Job:
    return Job(
        title=title,
        company=company,
        location=location,
        url=f"https://example.com/jobs/{external_id}",
        source=source,
        external_id=external_id,
    )


def test_removes_invalid_titles(
    pipeline: JobQualityPipeline,
) -> None:
    jobs = [
        make_job("Jobs", external_id="1"),
        make_job("Template", external_id="2"),
        make_job("F", external_id="3"),
        make_job("QA Engineer", external_id="4"),
    ]

    result = pipeline.clean(
        jobs,
        query="QA Engineer",
    )

    assert [job.title for job in result] == [
        "QA Engineer",
    ]


def test_filters_jobs_not_relevant_to_qa_query(
    pipeline: JobQualityPipeline,
) -> None:
    jobs = [
        make_job("QA Engineer", external_id="1"),
        make_job("Senior Quality Engineer", external_id="2"),
        make_job("Software Tester", external_id="3"),
        make_job("Senior AI Engineer", external_id="4"),
        make_job("Copywriter", external_id="5"),
        make_job("Sales Assistant", external_id="6"),
    ]

    result = pipeline.clean(
        jobs,
        query="QA Engineer",
    )

    assert [job.title for job in result] == [
        "QA Engineer",
        "Senior Quality Engineer",
        "Software Tester",
    ]


def test_keeps_qa_role_variants(
    pipeline: JobQualityPipeline,
) -> None:
    jobs = [
        make_job("QA Engineer", external_id="1"),
        make_job("Quality Assurance Engineer", external_id="2"),
        make_job("Quality Analyst", external_id="3"),
        make_job("Test Automation Engineer", external_id="4"),
        make_job("SDET", external_id="5"),
    ]

    result = pipeline.clean(
        jobs,
        query="QA Engineer",
    )

    assert len(result) == 5


def test_normalizes_job_text(
    pipeline: JobQualityPipeline,
) -> None:
    job = make_job(
        "  Senior   QA Engineer  ",
        company="  Test &amp; Company  ",
    )

    result = pipeline.clean(
        [job],
        query="QA Engineer",
    )

    assert len(result) == 1
    assert result[0].title == "Senior QA Engineer"
    assert result[0].company == "Test & Company"


def test_query_matching_is_case_insensitive(
    pipeline: JobQualityPipeline,
) -> None:
    jobs = [
        make_job("Senior QA Engineer"),
    ]

    result = pipeline.clean(
        jobs,
        query="qa ENGINEER",
    )

    assert len(result) == 1


def test_unknown_query_does_not_apply_role_filter(
    pipeline: JobQualityPipeline,
) -> None:
    jobs = [
        make_job("Copywriter", external_id="1"),
        make_job("Backend Engineer", external_id="2"),
    ]

    result = pipeline.clean(
        jobs,
        query="Unknown Profession",
    )

    assert len(result) == 2
