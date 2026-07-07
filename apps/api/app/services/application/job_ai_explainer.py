import logging

from google.genai import types

from app.schemas.job import Job
from app.schemas.resume_profile import ResumeProfile
from app.schemas.job_explanation import JobExplanation
from app.services.ai.factory import get_ai


logger = logging.getLogger(__name__)


class JobAIExplainer:

    def __init__(self):
        self.ai = get_ai()

    def explain(
        self,
        profile: ResumeProfile,
        job: Job,
        score: float,
    ) -> JobExplanation:

        prompt = f"""
You are an expert technical recruiter.

Analyze how well this vacancy matches the candidate.

Return ONLY valid JSON.

Format:

{{
    "why_match": "...",
    "missing_skills": [
        "...",
        "..."
    ],
    "recommendation": "good_fit"
}}

Candidate:

{profile.resume_text}

Job:

Title: {job.title}
Company: {job.company}
Location: {job.location}
Source: {job.source}
URL: {job.url}

Current Score: {score}
"""

        try:
            response = self.ai.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=JobExplanation,
                ),
            )

            if response.parsed is None:
                logger.warning(
                    "Gemini returned empty parsed response for job: %s",
                    job.title,
                )

                return self._fallback_explanation(
                    job=job,
                    score=score,
                )

            return response.parsed

        except Exception:
            logger.exception(
                "Gemini explanation failed for job: %s",
                job.title,
            )

            return self._fallback_explanation(
                job=job,
                score=score,
            )

    def _fallback_explanation(
        self,
        job: Job,
        score: float,
    ) -> JobExplanation:

        if score >= 70:
            recommendation = "good_fit"
            why_match = (
                "The vacancy has a strong rule-based match with "
                "the candidate profile."
            )

        elif score >= 40:
            recommendation = "possible_fit"
            why_match = (
                "The vacancy has a partial rule-based match with "
                "the candidate profile."
            )

        else:
            recommendation = "low_fit"
            why_match = (
                "The vacancy currently has a low rule-based match with "
                "the candidate profile."
            )

        return JobExplanation(
            why_match=why_match,
            missing_skills=[],
            recommendation=recommendation,
        )