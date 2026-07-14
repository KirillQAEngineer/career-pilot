import pytest
from pydantic import ValidationError

from app.schemas.job_comment import JobCommentUpsert


def test_job_comment_upsert_normalizes_values():
    request = JobCommentUpsert(
        job_source=" Adzuna ",
        job_external_id=" 123 ",
        comment="  Follow up on Friday.  ",
    )

    assert request.job_source == "Adzuna"
    assert request.job_external_id == "123"
    assert request.comment == "Follow up on Friday."


@pytest.mark.parametrize("field", ["job_source", "job_external_id"])
def test_job_comment_upsert_rejects_blank_identity(field):
    data = {
        "job_source": "adzuna",
        "job_external_id": "123",
        "comment": "Note",
    }
    data[field] = "   "

    with pytest.raises(ValidationError):
        JobCommentUpsert(**data)


def test_job_comment_upsert_rejects_comment_over_limit():
    with pytest.raises(ValidationError):
        JobCommentUpsert(
            job_source="adzuna",
            job_external_id="123",
            comment="x" * 2001,
        )
