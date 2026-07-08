from pydantic import BaseModel


class Job(BaseModel):
    title: str
    company: str
    location: str
    url: str
    source: str
    external_id: str
