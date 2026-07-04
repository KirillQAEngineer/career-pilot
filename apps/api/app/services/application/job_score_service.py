from app.schemas.job import Job
from app.schemas.resume_profile import ResumeProfile


class JobScoreService:

    def calculate(
    self,
    profile: ResumeProfile,
    job: Job,
) -> int:

        score = 0

        text = " ".join([
            job.title,
            job.company,
            job.location,
            job.source,
        ]).lower()

        if profile.profession.lower() in text:
            score += 40

        if profile.level.lower() in text:
            score += 20

        for skill in profile.skills:
            if skill.lower() in text:
                score += 8

        for technology in profile.technologies:
            if technology.lower() in text:
                score += 6

        for role in profile.preferred_roles:
            if role.lower() in text:
                score += 10

        return min(score, 100)