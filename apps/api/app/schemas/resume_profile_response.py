from pydantic import BaseModel


class ResumeProfileResponse(BaseModel):
    id: int
    profession: str
    level: str
    skills: str
    technologies: str
    english_level: str
    preferred_roles: str
    resume_text: str

    model_config = {
        "from_attributes": True
    }