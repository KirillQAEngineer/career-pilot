from sqlalchemy.orm import Session

from app.db.models.job_interaction import JobInteraction


class JobInteractionScorer:

    def __init__(self, db: Session):
        self.db = db

    def score(self, user_id: int, job) -> float:

        interactions = (
            self.db.query(JobInteraction)
            .filter(JobInteraction.user_id == user_id)
            .all()
        )

        score = 0.0

        job_title = job.title.lower()
        job_company = job.company.lower()

        for i in interactions:

            title_match = i.job_title.lower() in job_title or job_title in i.job_title.lower()
            company_match = i.job_company.lower() == job_company

            if not title_match and not company_match:
                continue

            if i.action == "like":
                score += 10

            elif i.action == "dislike":
                score -= 15

            elif i.action == "apply":
                score += 25

        return score