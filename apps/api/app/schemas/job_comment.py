from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class JobCommentUpsert(BaseModel):
    job_source: str = Field(min_length=1)
    job_external_id: str = Field(min_length=1)
    comment: str = Field(max_length=2000)

    @field_validator("job_source", "job_external_id")
    @classmethod
    def validate_identity_part(cls, value: str) -> str:
        normalized_value = value.strip()

        if not normalized_value:
            raise ValueError("Stable job identity is required")

        return normalized_value

    @field_validator("comment")
    @classmethod
    def normalize_comment(cls, value: str) -> str:
        return value.strip()


class JobCommentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    job_source: str
    job_external_id: str
    comment: str
    updated_at: datetime | None
