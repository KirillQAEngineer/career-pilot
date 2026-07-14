from datetime import datetime
from typing import Literal

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


ApplicationStatus = Literal[
    "applied",
    "screening",
    "interview",
    "technical_interview",
    "offer",
    "rejected",
]


class ApplicationStatusUpdate(BaseModel):
    status: ApplicationStatus


class ApplicationStatsResponse(BaseModel):
    total_applications: int
    active_processes: int
    interviews: int
    offers: int
    rejected: int


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
