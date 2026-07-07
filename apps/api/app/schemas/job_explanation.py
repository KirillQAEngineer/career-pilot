from pydantic import BaseModel


class JobExplanation(BaseModel):
    why_match: str
    missing_skills: list[str]
    recommendation: str