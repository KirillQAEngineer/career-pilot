import logging

from google.genai import types

from app.schemas.job import Job
from app.schemas.resume_profile import ResumeProfile
from app.services.ai.factory import get_ai


logger = logging.getLogger(__name__)


class JobCoverLetterService:

    def __init__(self):
        self.ai = get_ai()

    def generate(
        self,
        profile: ResumeProfile,
        job: Job,
    ) -> str:
        prompt = f"""
You are an expert recruiter and career coach.

Write a short, professional cover letter in 4-6 sentences.
Use plain text only.
Keep it specific to the vacancy and candidate background.
Do not invent experience that is not grounded in the candidate profile.

Candidate profile:
Profession: {profile.profession}
Level: {profile.level}
Skills: {", ".join(profile.skills)}
Technologies: {", ".join(profile.technologies)}
English level: {profile.english_level}
Preferred roles: {", ".join(profile.preferred_roles)}

Job:
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
                    response_mime_type="text/plain",
                ),
            )

            text = (response.text or "").strip()

            if text:
                return text
        except Exception:
            logger.exception(
                "Gemini cover letter generation failed for job: %s",
                job.title,
            )

        return self._fallback_cover_letter(profile, job)

    def _fallback_cover_letter(
        self,
        profile: ResumeProfile,
        job: Job,
    ) -> str:
        primary_skills = ", ".join(profile.skills[:3])

        return (
            f"Hello {job.company} team,\n\n"
            f"I am a {profile.level.lower()} {profile.profession} interested "
            f"in the {job.title} role. My background includes {primary_skills}, "
            f"which aligns well with the responsibilities of this position. "
            f"I would be glad to contribute this experience to your team and "
            f"learn more about the opportunity.\n\n"
            "Best regards,"
        )
