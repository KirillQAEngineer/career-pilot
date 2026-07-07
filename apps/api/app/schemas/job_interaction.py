from pydantic import BaseModel


class JobInteractionRequest(BaseModel):
    job_title: str
    job_company: str
    job_url: str
    action: str  # like | dislike | apply