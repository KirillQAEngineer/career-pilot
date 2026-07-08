from pydantic import BaseModel


class JobInteractionRequest(BaseModel):
    job_title: str
    job_company: str
    job_url: str
    job_source: str
    job_external_id: str
    action: str  # like | dislike | apply
