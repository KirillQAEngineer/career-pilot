from google import genai

from app.core.config import settings
from app.services.ai.base import AIProvider
from app.schemas.analysis import AnalysisResponse
from app.schemas.resume_profile import ResumeProfile
from google.genai import types

from app.prompts.job_match import JOB_MATCH_PROMPT
from app.schemas.job_match import JobMatch
from app.schemas.job import Job
from app.prompts.resume_profile import RESUME_PROFILE_PROMPT
from app.prompts.resume_review import RESUME_REVIEW_PROMPT


class GeminiProvider(AIProvider):

    def __init__(self):
        self.client = genai.Client(
            api_key=settings.gemini_api_key,
        )
        
    def _generate_json(
        self,
        prompt: str,
        schema,
    ):

        response = self.client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=schema,
            ),
        )

        return response.parsed

    def analyze_resume(
        self,
        text: str,
    ) -> AnalysisResponse:

        return self._generate_json(
            prompt=f"""
    {RESUME_REVIEW_PROMPT}

    {text}
    """,
            schema=AnalysisResponse,
        )

    def build_resume_profile(
        self,
        text: str,
    ) -> ResumeProfile:

        return self._generate_json(
            prompt=f"""
    {RESUME_PROFILE_PROMPT}

    {text}
    """,
            schema=ResumeProfile,
        )
    
    def match_job(
        self,
        resume_text: str,
        job: Job,
    ) -> JobMatch:

        return self._generate_json(
            prompt=f"""
    {JOB_MATCH_PROMPT}

    Resume:

    {resume_text}

    Job:

    Title: {job.title}
    Company: {job.company}
    Location: {job.location}
    Source: {job.source}
    URL: {job.url}
    """,
            schema=JobMatch,
        )