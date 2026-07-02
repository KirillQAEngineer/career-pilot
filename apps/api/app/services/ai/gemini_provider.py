from google import genai

from app.core.config import settings
from app.services.ai.base import AIProvider
from app.schemas.analysis import AnalysisResponse
from app.schemas.resume_profile import ResumeProfile
from google.genai import types

from app.prompts.job_match import JOB_MATCH_PROMPT
from app.schemas.job_match import JobMatch


class GeminiProvider(AIProvider):

    def __init__(self):
        self.client = genai.Client(
            api_key=settings.gemini_api_key,
        )

    def analyze_resume(self, text: str) -> AnalysisResponse:

        # Пока заглушка
        return AnalysisResponse(
            summary="Gemini connected",
            score=100,
            strengths=["Gemini API works"],
            weaknesses=[],
            recommendations=[],
        )

    def build_resume_profile(self, text: str) -> ResumeProfile:

        # Пока заглушка
        return ResumeProfile(
            profession="QA Engineer",
            level="Senior",
            skills=["Python"],
            technologies=["Docker"],
            english_level="B1",
            preferred_roles=["QA Engineer"],
        )
    
    def analyze_job(
    self,
    resume_text: str,
    job_description: str,
) -> JobMatch:

        response = self.client.models.generate_content(
        model="gemini-2.5-flash",
        contents=f"""
{JOB_MATCH_PROMPT}

Resume:

{resume_text}

Job description:

{job_description}
""",
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=JobMatch,
        ),
    )

        return response.parsed