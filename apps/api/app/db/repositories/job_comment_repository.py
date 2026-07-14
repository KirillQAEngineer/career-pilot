from sqlalchemy.orm import Session

from app.db.models.job_comment import JobComment
from app.db.repositories.job_interaction_repository import build_job_identity


class JobCommentRepository:

    def __init__(self, db: Session):
        self.db = db

    def get_by_user_id(self, user_id: int) -> list[JobComment]:
        return (
            self.db.query(JobComment)
            .filter(JobComment.user_id == user_id)
            .order_by(JobComment.updated_at.desc())
            .all()
        )

    def get_by_identity(
        self,
        user_id: int,
        job_source: str,
        job_external_id: str,
    ) -> JobComment | None:
        identity = build_job_identity(job_source, job_external_id)

        if identity is None:
            return None

        return (
            self.db.query(JobComment)
            .filter(
                JobComment.user_id == user_id,
                JobComment.job_source == identity[0],
                JobComment.job_external_id == identity[1],
            )
            .first()
        )

    def upsert(
        self,
        user_id: int,
        data: dict,
    ) -> JobComment | dict:
        identity = build_job_identity(
            data["job_source"],
            data["job_external_id"],
        )

        if identity is None:
            raise ValueError("Stable job identity is required")

        comment_text = data["comment"].strip()

        existing = self.get_by_identity(
            user_id,
            identity[0],
            identity[1],
        )

        if not comment_text:
            if existing is not None:
                self.db.delete(existing)
                self.db.commit()

            return {
                "job_source": identity[0],
                "job_external_id": identity[1],
                "comment": "",
                "updated_at": None,
            }

        if existing is None:
            existing = JobComment(
                user_id=user_id,
                job_source=identity[0],
                job_external_id=identity[1],
                comment=comment_text,
            )
            self.db.add(existing)
        else:
            existing.comment = comment_text

        self.db.commit()
        self.db.refresh(existing)

        return existing
