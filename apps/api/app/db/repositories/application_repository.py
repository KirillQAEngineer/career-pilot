from sqlalchemy import func
from sqlalchemy.orm import Session

from app.db.models.application import Application


class ApplicationRepository:

    def __init__(self, db: Session):
        self.db = db

    def get_by_user_and_identity(
        self,
        user_id: int,
        job_source: str,
        job_external_id: str,
    ) -> Application | None:
        return (
            self.db.query(Application)
            .filter(
                Application.user_id == user_id,
                Application.job_source == job_source,
                Application.job_external_id == job_external_id,
            )
            .first()
        )

    def create_from_interaction(
        self,
        user_id: int,
        data: dict,
    ) -> Application:
        existing = self.get_by_user_and_identity(
            user_id,
            data["job_source"],
            data["job_external_id"],
        )

        if existing is not None:
            return existing

        application = Application(
            user_id=user_id,
            job_title=data["job_title"],
            job_company=data["job_company"],
            job_url=data["job_url"],
            job_location=data.get("job_location"),
            job_work_format=data.get("job_work_format"),
            job_published_at=data.get("job_published_at"),
            job_source=data["job_source"],
            job_external_id=data["job_external_id"],
            status="applied",
        )

        self.db.add(application)
        self.db.commit()
        self.db.refresh(application)

        return application

    def get_by_user_id(
        self,
        user_id: int,
    ) -> list[Application]:
        return (
            self.db.query(Application)
            .filter(Application.user_id == user_id)
            .order_by(Application.updated_at.desc())
            .all()
        )

    def get_stats(
        self,
        user_id: int,
    ) -> dict[str, int]:
        status_counts = dict(
            self.db.query(
                Application.status,
                func.count(Application.id),
            )
            .filter(Application.user_id == user_id)
            .group_by(Application.status)
            .all()
        )

        applied = status_counts.get("applied", 0)
        screening = status_counts.get("screening", 0)
        interview = status_counts.get("interview", 0)
        technical_interview = status_counts.get(
            "technical_interview",
            0,
        )
        offers = status_counts.get("offer", 0)
        rejected = status_counts.get("rejected", 0)

        return {
            "total_applications": sum(status_counts.values()),
            "active_processes": (
                applied
                + screening
                + interview
                + technical_interview
            ),
            "interviews": interview + technical_interview,
            "offers": offers,
            "rejected": rejected,
        }

    def update_status(
        self,
        user_id: int,
        application_id: int,
        status: str,
    ) -> Application | None:
        application = (
            self.db.query(Application)
            .filter(
                Application.id == application_id,
                Application.user_id == user_id,
            )
            .first()
        )

        if application is None:
            return None

        application.status = status

        self.db.commit()
        self.db.refresh(application)

        return application
