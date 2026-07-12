from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ApplicationCreate(BaseModel):
    job_title: str
    job_company: str
    job_url: str

    job_location: str | None = None
    job_work_format: str | None = None
    job_published_at: str | None = None

    job_source: str
    job_external_id: str


class ApplicationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int

    job_title: str
    job_company: str
    job_url: str

    job_location: str | None
    job_work_format: str | None
    job_published_at: str | None

    job_source: str
    job_external_id: str

    status: str

    created_at: datetime
    updated_at: datetime
