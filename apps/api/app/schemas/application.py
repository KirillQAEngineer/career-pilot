from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class ApplicationCreate(BaseModel):
    job_title: str
    job_company: str
    job_url: str

    job_location: str | None = None
    job_work_format: str | None = None
    job_published_at: str | None = None
    job_description: str | None = None

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


class ApplicationAnalyticsUpdate(BaseModel):
    total_applications: int | None = Field(default=None, ge=0)
    total_screenings: int | None = Field(default=None, ge=0)
    total_interviews: int | None = Field(default=None, ge=0)
    total_offers: int | None = Field(default=None, ge=0)
    total_rejected: int | None = Field(default=None, ge=0)


class ApplicationStatsResponse(BaseModel):
    total_applications: int
    total_screenings: int
    total_interviews: int
    total_offers: int
    total_rejected: int

    active_processes: int

    screening_in_progress: int
    interview_in_progress: int
    technical_interview_in_progress: int
    offer_in_progress: int

    # Backward-compatible aliases for the current Flutter client.
    interviews: int
    offers: int
    rejected: int


class ApplicationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int

    job_title: str
    job_company: str
    job_url: str

    job_location: str | None
    job_work_format: str | None
    job_published_at: str | None
    job_description: str | None

    job_source: str
    job_external_id: str

    status: str

    created_at: datetime
    updated_at: datetime
    archived_at: datetime | None
