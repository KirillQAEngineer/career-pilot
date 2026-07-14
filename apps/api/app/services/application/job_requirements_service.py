import logging

from google.genai import types

from app.schemas.job import Job
from app.schemas.job_requirements import JobRequirementsResponse
from app.services.ai.factory import get_ai


logger = logging.getLogger(__name__)


class JobRequirementsService:

    def __init__(self):
        self.ai = get_ai()

    def extract(
        self,
        job: Job,
    ) -> JobRequirementsResponse:
        prompt = f"""
You are an expert recruiter.

Extract the required skills, technologies, tools, frameworks, and methods for this vacancy.
Return only valid JSON.

Format:
{{
  "required_skills": ["Skill 1", "Skill 2"],
  "skills_summary": "A concise summary of the technical stack and expectations."
}}

Vacancy:
Title: {job.title}
Company: {job.company}
Location: {job.location}
Description: {job.description or ""}
"""

        try:
            response = self.ai.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=JobRequirementsResponse,
                ),
            )

            if response.parsed is not None:
                return response.parsed
        except Exception:
            logger.exception(
                "Gemini requirements extraction failed for job: %s",
                job.title,
            )

        return self._fallback(job)

    def _fallback(
        self,
        job: Job,
    ) -> JobRequirementsResponse:
        description = (job.description or "").strip()

        if not description:
            return JobRequirementsResponse(
                required_skills=[],
                skills_summary=(
                    "Structured technical requirements are not available "
                    "for this vacancy yet."
                ),
            )

        normalized = " ".join(description.split())
        fragments = [
            fragment.strip(" .,:;")
            for fragment in normalized.replace("/", ",").split(",")
        ]

        required_skills = []
        for fragment in fragments:
            if len(fragment) < 3:
                continue

            if fragment not in required_skills:
                required_skills.append(fragment)

            if len(required_skills) == 8:
                break

        return JobRequirementsResponse(
            required_skills=required_skills,
            skills_summary=(
                "The vacancy emphasizes the technologies, tools, and delivery "
                "expectations listed below."
            ),
        )
