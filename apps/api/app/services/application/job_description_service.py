import logging

from google.genai import types

from app.schemas.job import Job
from app.schemas.job_description_response import JobDescriptionResponse
from app.services.ai.factory import get_ai


logger = logging.getLogger(__name__)


class JobDescriptionService:

    def __init__(self):
        self.ai = get_ai()

    def format(
        self,
        job: Job,
    ) -> JobDescriptionResponse:
        raw_description = (job.description or "").strip()

        if not raw_description:
            return JobDescriptionResponse(description=None)

        prompt = f"""
You are an expert technical recruiter.

Rewrite the vacancy description into a clean, complete, well-structured version.
Rules:
- Keep plain text only.
- Use full wording without abbreviations where the meaning is clear.
- Preserve only information grounded in the source description.
- Organize the text into sections:
  Role Overview
  Responsibilities
  Requirements
  Conditions

Vacancy:
Title: {job.title}
Company: {job.company}
Location: {job.location}

Source description:
{raw_description}
"""

        try:
            response = self.ai.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="text/plain",
                ),
            )

            text = (response.text or "").strip()

            if text:
                return JobDescriptionResponse(description=text)
        except Exception:
            logger.exception(
                "Gemini description formatting failed for job: %s",
                job.title,
            )

        return JobDescriptionResponse(
            description=self._fallback(raw_description),
        )

    def _fallback(
        self,
        raw_description: str,
    ) -> str:
        normalized = " ".join(raw_description.split())

        return (
            "Role Overview\n"
            f"{normalized}\n\n"
            "Responsibilities\n"
            "See the source description above.\n\n"
            "Requirements\n"
            "See the source description above.\n\n"
            "Conditions\n"
            "See the source description above."
        )
