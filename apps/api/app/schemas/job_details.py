from pydantic import BaseModel

from app.schemas.job import Job


class JobDetailsResponse(BaseModel):
    job: Job
    match: int
    why_match: str
    missing_skills: list[str]
    recommendation: str
    cover_letter: str
    description: str | None = None
