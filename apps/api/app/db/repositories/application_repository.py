from datetime import datetime, timezone

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.db.models.application import Application
from app.db.models.application_analytics_adjustment import (
    ApplicationAnalyticsAdjustment,
)
from app.db.repositories.job_interaction_repository import (
    build_job_identity,
    normalize_job_text,
    normalize_job_url,
)


ANALYTICS_TOTAL_FIELDS = (
    "total_applications",
    "total_screenings",
    "total_interviews",
    "total_offers",
    "total_rejected",
)


class ApplicationRepository:

    def __init__(self, db: Session):
        self.db = db

    def _build_job_fingerprint(
        self,
        *,
        job_title: str,
        job_company: str,
        job_location: str | None,
    ) -> tuple[str, str, str] | None:
        normalized_title = normalize_job_text(job_title)
        normalized_company = normalize_job_text(job_company)
        normalized_location = normalize_job_text(job_location)

        if not normalized_title or not normalized_company:
            return None

        return (
            normalized_title,
            normalized_company,
            normalized_location,
        )

    def _find_existing_application(
        self,
        user_id: int,
        data: dict,
    ) -> Application | None:
        job_identity = build_job_identity(
            data["job_source"],
            data["job_external_id"],
        )

        if job_identity is not None:
            existing = self.get_by_user_and_identity(
                user_id,
                job_identity[0],
                job_identity[1],
            )

            if existing is not None:
                return existing

        normalized_job_url = normalize_job_url(data["job_url"])
        job_fingerprint = self._build_job_fingerprint(
            job_title=data["job_title"],
            job_company=data["job_company"],
            job_location=data.get("job_location"),
        )

        existing_applications = (
            self.db.query(Application)
            .filter(Application.user_id == user_id)
            .all()
        )

        for application in existing_applications:
            if normalized_job_url and (
                normalize_job_url(application.job_url) == normalized_job_url
            ):
                return application

            existing_fingerprint = self._build_job_fingerprint(
                job_title=application.job_title,
                job_company=application.job_company,
                job_location=application.job_location,
            )
            existing_identity = build_job_identity(
                application.job_source or "",
                application.job_external_id or "",
            )

            if (
                job_fingerprint is not None
                and existing_fingerprint == job_fingerprint
                and (
                    job_identity is None
                    or existing_identity is None
                )
            ):
                return application

        return None

    def _update_missing_metadata(
        self,
        application: Application,
        data: dict,
    ) -> bool:
        updated = False

        metadata_fields = {
            "job_location": "job_location",
            "job_work_format": "job_work_format",
            "job_published_at": "job_published_at",
            "job_description": "job_description",
        }

        for model_field, data_field in metadata_fields.items():
            current_value = getattr(application, model_field)
            new_value = data.get(data_field)

            if not current_value and new_value:
                setattr(application, model_field, new_value)
                updated = True

        return updated

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
        existing = self._find_existing_application(
            user_id,
            data,
        )

        if existing is not None:
            updated = self._update_missing_metadata(existing, data)

            job_identity = build_job_identity(
                data["job_source"],
                data["job_external_id"],
            )

            if (
                job_identity is not None
                and (
                    not existing.job_source
                    or not existing.job_external_id
                )
            ):
                existing.job_source = job_identity[0]
                existing.job_external_id = job_identity[1]
                updated = True

            if existing.archived_at is not None:
                existing.archived_at = None
                updated = True

            if updated:
                self.db.commit()
                self.db.refresh(existing)

            return existing

        application = Application(
            user_id=user_id,
            job_title=data["job_title"],
            job_company=data["job_company"],
            job_url=data["job_url"],
            job_location=data.get("job_location"),
            job_work_format=data.get("job_work_format"),
            job_published_at=data.get("job_published_at"),
            job_description=data.get("job_description"),
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
        *,
        include_archived: bool = False,
    ) -> list[Application]:
        query = self.db.query(Application).filter(Application.user_id == user_id)

        if not include_archived:
            query = query.filter(Application.archived_at.is_(None))

        return query.order_by(Application.updated_at.desc()).all()

    def get_stats(
        self,
        user_id: int,
    ) -> dict[str, int]:
        status_counts = dict(
            self.db.query(
                Application.status,
                func.count(Application.id),
            )
            .filter(
                Application.user_id == user_id,
                Application.archived_at.is_(None),
            )
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

        automatic_totals = {
            "total_applications": sum(status_counts.values()),
            "total_screenings": screening,
            "total_interviews": interview + technical_interview,
            "total_offers": offers,
            "total_rejected": rejected,
        }

        adjustment = (
            self.db.query(ApplicationAnalyticsAdjustment)
            .filter(ApplicationAnalyticsAdjustment.user_id == user_id)
            .first()
        )

        analytics_totals = {
            field: (
                getattr(adjustment, field)
                if adjustment is not None
                and getattr(adjustment, field) is not None
                else automatic_totals[field]
            )
            for field in ANALYTICS_TOTAL_FIELDS
        }

        return {
            **analytics_totals,
            "active_processes": (
                applied
                + screening
                + interview
                + technical_interview
            ),
            "screening_in_progress": screening,
            "interview_in_progress": interview,
            "technical_interview_in_progress": technical_interview,
            "offer_in_progress": offers,
            "interviews": analytics_totals["total_interviews"],
            "offers": analytics_totals["total_offers"],
            "rejected": analytics_totals["total_rejected"],
        }

    def update_analytics_adjustment(
        self,
        user_id: int,
        data: dict[str, int | None],
    ) -> ApplicationAnalyticsAdjustment | None:
        adjustment = (
            self.db.query(ApplicationAnalyticsAdjustment)
            .filter(ApplicationAnalyticsAdjustment.user_id == user_id)
            .first()
        )

        if adjustment is None:
            if not data:
                return None

            adjustment = ApplicationAnalyticsAdjustment(
                user_id=user_id,
                **data,
            )
            self.db.add(adjustment)
        else:
            for field, value in data.items():
                setattr(adjustment, field, value)

        self.db.commit()
        self.db.refresh(adjustment)

        return adjustment

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

    def archive(
        self,
        user_id: int,
        application_id: int,
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

        application.archived_at = datetime.now(timezone.utc)

        self.db.commit()
        self.db.refresh(application)

        return application

    def unarchive(
        self,
        user_id: int,
        application_id: int,
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

        application.archived_at = None

        self.db.commit()
        self.db.refresh(application)

        return application
