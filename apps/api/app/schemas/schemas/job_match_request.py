from pydantic import BaseModel

from app.schemas.job import Job


class JobMatchRequest(BaseModel):
    job: Job