from abc import ABC, abstractmethod

from app.schemas.analysis import AnalysisResponse
from app.schemas.resume_profile import ResumeProfile
from app.schemas.job_match import JobMatch

class AIProvider(ABC):

    @abstractmethod
    def analyze_resume(self, text: str) -> AnalysisResponse:
        pass

    @abstractmethod
    def build_resume_profile(self, text: str) -> ResumeProfile:
        pass

    def analyze_job(
    self,
    resume_text: str,
    job_description: str,
) -> JobMatch:
        raise NotImplementedError