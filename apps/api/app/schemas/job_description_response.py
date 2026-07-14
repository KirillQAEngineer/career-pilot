from pydantic import BaseModel


class JobDescriptionResponse(BaseModel):
    description: str | None = None
