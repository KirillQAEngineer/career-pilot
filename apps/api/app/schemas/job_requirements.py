from pydantic import BaseModel


class JobRequirementsResponse(BaseModel):
    required_skills: list[str]
    skills_summary: str
