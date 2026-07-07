from sqlalchemy.orm import Session

from app.db.models.job_interaction import JobInteraction


class JobInteractionRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        user_id: int,
        data: dict,
    ) -> JobInteraction:

        existing_interaction = (
            self.db.query(JobInteraction)
            .filter(
                JobInteraction.user_id == user_id,
                JobInteraction.job_url == data["job_url"],
                JobInteraction.action == data["action"],
            )
            .first()
        )

        if existing_interaction is not None:
            return existing_interaction

        interaction = JobInteraction(
            user_id=user_id,
            job_title=data["job_title"],
            job_company=data["job_company"],
            job_url=data["job_url"],
            action=data["action"],
        )

        self.db.add(interaction)
        self.db.commit()
        self.db.refresh(interaction)

        return interaction

    def get_saved_by_user_id(
        self,
        user_id: int,
    ) -> list[JobInteraction]:

        return (
            self.db.query(JobInteraction)
            .filter(
                JobInteraction.user_id == user_id,
                JobInteraction.action == "like",
            )
            .order_by(
                JobInteraction.created_at.desc(),
            )
            .all()
        )

    def delete_saved_by_user_and_url(
        self,
        user_id: int,
        job_url: str,
    ) -> bool:

        interaction = (
            self.db.query(JobInteraction)
            .filter(
                JobInteraction.user_id == user_id,
                JobInteraction.job_url == job_url,
                JobInteraction.action == "like",
            )
            .first()
        )

        if interaction is None:
            return False

        self.db.delete(interaction)
        self.db.commit()

        return True