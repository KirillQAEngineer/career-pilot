from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.schemas.resume_profile import ResumeProfile
from app.services.application.resume_service import ResumeService


def test_resume_service_builds_fallback_profile_from_resume_text():
    service = ResumeService.__new__(ResumeService)

    profile = service._fallback_profile(
        "Senior QA Engineer with API testing, SQL, Postman, Docker and regression testing."
    )

    assert profile.profession == "QA Engineer"
    assert profile.level == "Senior"
    assert "API Testing" in profile.skills
    assert "SQL" in profile.skills
    assert "Postman" in profile.technologies
    assert "Docker" in profile.technologies
    assert "Regression Testing" in profile.skills


def test_resume_service_keeps_comprehensive_resume_technology_lists():
    service = ResumeService.__new__(ResumeService)

    profile = service._fallback_profile(
        """
        QA Engineer. Manual, smoke, regression, integration and API testing.
        Created test cases and checklists, analyzed requirements and defects.
        Tools: Postman, Swagger, Charles Proxy, Jira, TestRail, Git,
        GitLab CI, Docker, PostgreSQL, Kafka, Grafana and Kibana.
        Used Python, Pytest, Selenium and Playwright for test automation.
        """
    )

    assert {
        "API Testing",
        "Manual Testing",
        "Smoke Testing",
        "Regression Testing",
        "Integration Testing",
        "Test Cases",
        "Checklists",
        "Requirements Analysis",
    }.issubset(profile.skills)
    assert {
        "Postman",
        "Swagger",
        "Charles Proxy",
        "Jira",
        "TestRail",
        "GitLab CI",
        "Docker",
        "PostgreSQL",
        "Kafka",
        "Grafana",
        "Kibana",
        "Python",
        "Pytest",
        "Selenium",
        "Playwright",
    }.issubset(profile.technologies)


def test_resume_service_builds_fallback_analysis():
    service = ResumeService.__new__(ResumeService)

    analysis = service._fallback_analysis("QA Engineer resume text")

    assert analysis.score == 60
    assert analysis.summary
    assert analysis.recommendations


def test_resume_upload_preserves_manually_entered_profile_lists():
    service = ResumeService.__new__(ResumeService)
    service.repository = SimpleNamespace(
        get_by_user_id=lambda user_id: SimpleNamespace(
            skills="Exploratory Testing,SQL",
            technologies="Postman,PostgreSQL",
            preferred_roles="QA Engineer",
        )
    )
    extracted = ResumeProfile(
        profession="QA Engineer",
        level="Middle",
        skills=["SQL", "API Testing"],
        technologies=["Docker", "Postman"],
        english_level="B2",
        preferred_roles=["Test Engineer"],
    )

    merged = service._merge_existing_profile(42, extracted)

    assert merged.skills == [
        "Exploratory Testing",
        "SQL",
        "API Testing",
    ]
    assert merged.technologies == ["Postman", "PostgreSQL", "Docker"]
    assert merged.preferred_roles == ["QA Engineer", "Test Engineer"]


def test_resume_upload_rejects_content_that_does_not_match_extension():
    service = ResumeService.__new__(ResumeService)

    with pytest.raises(HTTPException) as exception:
        service._validate_file_signature(".pdf", b"MZ executable content")

    assert exception.value.status_code == 400


@pytest.mark.parametrize(
    ("suffix", "content"),
    [(".pdf", b"%PDF-1.7"), (".docx", b"PK\x03\x04")],
)
def test_resume_upload_accepts_supported_file_signatures(suffix, content):
    service = ResumeService.__new__(ResumeService)

    service._validate_file_signature(suffix, content)
