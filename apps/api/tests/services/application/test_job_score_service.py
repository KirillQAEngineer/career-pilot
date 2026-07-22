from app.schemas.job import Job
from app.services.application.job_score_service import (
    JobScoreService,
)


def make_job(title: str) -> Job:
    return Job(
        title=title,
        company="Acme",
        location="Remote",
        url="https://example.com/job",
        source="TestProvider",
        external_id="1",
    )


def test_scores_qa_engineer_role_keywords():
    score = JobScoreService().score(
        "Senior QA Engineer with API test automation experience",
        make_job("Senior QA Automation Engineer"),
    )

    assert 70 <= score <= 100


def test_software_tester_is_not_spam_penalized():
    score = JobScoreService().score(
        "QA tester with regression and API testing experience",
        make_job("Software Tester"),
    )

    assert score > 0
