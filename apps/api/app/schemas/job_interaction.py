from pydantic import BaseModel


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
