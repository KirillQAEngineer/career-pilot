from urllib.parse import urlsplit, urlunsplit

from sqlalchemy.orm import Session

from app.db.models.job_interaction import JobInteraction


INTERACTION_ACTIONS = (
    "like",
    "apply",
    "dislike",
)


def normalize_job_url(job_url: str) -> str:
    value = job_url.strip()

    if not value:
        return ""

    try:
        parts = urlsplit(value)

        normalized_path = parts.path.rstrip("/")

        return urlunsplit(
            (
                parts.scheme.lower(),
                parts.netloc.lower(),
                normalized_path,
                "",
                "",
            )
        )
    except ValueError:
        return value


def normalize_job_source(job_source: str) -> str:
    return job_source.strip().lower()


def normalize_job_external_id(job_external_id: str) -> str:
    return job_external_id.strip()


def build_job_identity(
    job_source: str,
    job_external_id: str,
) -> tuple[str, str] | None:
    normalized_source = normalize_job_source(job_source)
    normalized_external_id = normalize_job_external_id(
        job_external_id,
    )

    if not normalized_source or not normalized_external_id:
        return None

    return (
        normalized_source,
        normalized_external_id,
    )


class JobInteractionRepository:

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        user_id: int,
        data: dict,
    ) -> JobInteraction:
        job_url = data["job_url"]
        action = data["action"]

        normalized_job_url = normalize_job_url(job_url)

        job_identity = build_job_identity(
            data["job_source"],
            data["job_external_id"],
        )

        existing_interactions = (
            self.db.query(JobInteraction)
            .filter(
                JobInteraction.user_id == user_id,
                JobInteraction.action == action,
            )
            .all()
        )

        for interaction in existing_interactions:
            interaction_identity = build_job_identity(
                interaction.job_source or "",
                interaction.job_external_id or "",
            )

            if (
                job_identity is not None
                and interaction_identity == job_identity
            ):
                return interaction

            if (
                normalized_job_url
                and normalize_job_url(interaction.job_url)
                == normalized_job_url
            ):
                if (
                    interaction.job_source is None
                    or interaction.job_external_id is None
                ):
                    interaction.job_source = job_identity[0]
                    interaction.job_external_id = job_identity[1]

                    self.db.commit()
                    self.db.refresh(interaction)

                return interaction

        interaction = JobInteraction(
            user_id=user_id,
            job_title=data["job_title"],
            job_company=data["job_company"],
            job_url=job_url,
            job_source=job_identity[0],
            job_external_id=job_identity[1],
            action=action,
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

    def get_applied_by_user_id(
        self,
        user_id: int,
    ) -> list[JobInteraction]:
        return (
            self.db.query(JobInteraction)
            .filter(
                JobInteraction.user_id == user_id,
                JobInteraction.action == "apply",
            )
            .order_by(
                JobInteraction.created_at.desc(),
            )
            .all()
        )

    def get_interacted_job_identities(
        self,
        user_id: int,
    ) -> set[tuple[str, str]]:
        rows = (
            self.db.query(
                JobInteraction.job_source,
                JobInteraction.job_external_id,
            )
            .filter(
                JobInteraction.user_id == user_id,
                JobInteraction.action.in_(INTERACTION_ACTIONS),
                JobInteraction.job_source.isnot(None),
                JobInteraction.job_external_id.isnot(None),
            )
            .all()
        )

        identities = set()

        for job_source, job_external_id in rows:
            identity = build_job_identity(
                job_source,
                job_external_id,
            )

            if identity is not None:
                identities.add(identity)

        return identities

    def get_legacy_interacted_job_urls(
        self,
        user_id: int,
    ) -> set[str]:
        rows = (
            self.db.query(JobInteraction.job_url)
            .filter(
                JobInteraction.user_id == user_id,
                JobInteraction.action.in_(INTERACTION_ACTIONS),
                (
                    JobInteraction.job_source.is_(None)
                    | JobInteraction.job_external_id.is_(None)
                ),
            )
            .distinct()
            .all()
        )

        return {
            normalize_job_url(job_url)
            for (job_url,) in rows
            if job_url
        }

    def delete_saved_by_user_and_url(
        self,
        user_id: int,
        job_url: str,
    ) -> bool:
        normalized_job_url = normalize_job_url(job_url)

        interactions = (
            self.db.query(JobInteraction)
            .filter(
                JobInteraction.user_id == user_id,
                JobInteraction.action == "like",
            )
            .all()
        )

        interaction_to_delete = None

        for interaction in interactions:
            if (
                normalize_job_url(interaction.job_url)
                == normalized_job_url
            ):
                interaction_to_delete = interaction
                break

        if interaction_to_delete is None:
            return False

        self.db.delete(interaction_to_delete)
        self.db.commit()

        return True
