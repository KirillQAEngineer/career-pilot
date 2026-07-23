from pydantic import BaseModel, field_validator


class ResumeProfileResponse(BaseModel):
    id: int
    profession: str
    level: str
    skills: str
    technologies: str
    english_level: str
    preferred_roles: str
    resume_text: str

    @field_validator(
        "skills",
        "technologies",
        "preferred_roles",
        mode="before",
    )
    @classmethod
    def format_comma_separated_values(cls, value: object) -> str:
        if not isinstance(value, str):
            return ""

        return ", ".join(
            item.strip()
            for item in value.split(",")
            if item.strip()
        )

    model_config = {
        "from_attributes": True
    }
