from pydantic import BaseModel


class JobMatch(BaseModel):
    match_percent: int
    strengths: list[str]
    missing_skills: list[str]
    recommendations: list[str]