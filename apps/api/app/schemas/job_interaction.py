from datetime import datetime

from pydantic import BaseModel, ConfigDict


class JobInteractionRequest(BaseModel):
    job_title: str
    job_company: str
    job_url: str

    job_location: str | None = None
    job_work_format: str | None = None
    job_published_at: str | None = None
    job_description: str | None = None

    job_source: str
    job_external_id: str
    action: str  # like | dislike | apply


class JobInteractionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    job_title: str
    job_company: str
    job_url: str
    job_location: str | None
    job_work_format: str | None
    job_published_at: str | None
    job_description: str | None
    job_source: str | None
    job_external_id: str | None
    action: str
    created_at: datetime | None
