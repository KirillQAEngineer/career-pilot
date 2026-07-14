from pydantic import BaseModel


class JobCoverLetterResponse(BaseModel):
    cover_letter: str
