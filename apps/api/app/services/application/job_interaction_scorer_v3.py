from datetime import datetime
from math import exp

from sqlalchemy.orm import Session

from app.db.models.job_interaction import JobInteraction


class JobInteractionScorerV3:

    ACTION_WEIGHTS = {
        "apply": 40,
        "like": 20,
        "view": 5,
        "dislike": -30,
    }

    DECAY_DAYS = 14  # через 2 недели сигнал почти уходит

    def __init__(self, db: Session):
        self.db = db

    def score(self, user_id: int, job) -> float:

        interactions = (
            self.db.query(JobInteraction)
            .filter(JobInteraction.user_id == user_id)
            .all()
        )

        job_title = job.title.lower()
        job_company = job.company.lower()

        score = 0.0

        now = datetime.utcnow()

        for i in interactions:

            base_weight = self.ACTION_WEIGHTS.get(i.action, 0)

            # match logic
            title_match = i.job_title.lower() in job_title or job_title in i.job_title.lower()
            company_match = i.job_company.lower() == job_company

            if not (title_match or company_match):
                continue

            # time decay
            if i.created_at:
                days = (now - i.created_at).days
            else:
                days = 999

            decay = exp(-days / self.DECAY_DAYS)

            score += base_weight * decay

        return score