from urllib.parse import urlsplit

from app.db.models.job_interaction import JobInteraction
from app.db.session import SessionLocal


def extract_identity(job_url: str) -> tuple[str, str] | None:
    parts = urlsplit(job_url)

    host = parts.netloc.lower()
    path_parts = [
        part
        for part in parts.path.split("/")
        if part
    ]

    if host in {"adzuna.com", "www.adzuna.com"}:
        if len(path_parts) >= 3 and path_parts[:2] == ["land", "ad"]:
            return "adzuna", path_parts[2]

    if host in {"jooble.org", "www.jooble.org"}:
        if len(path_parts) >= 2 and path_parts[0] == "jdp":
            return "jooble", path_parts[1]

    if host in {"remotive.com", "www.remotive.com"}:
        if not path_parts:
            return None

        slug = path_parts[-1]
        external_id = slug.rsplit("-", 1)[-1]

        if external_id.isdigit():
            return "remotive", external_id

    return None


def main() -> None:
    db = SessionLocal()

    try:
        interactions = (
            db.query(JobInteraction)
            .filter(
                (
                    JobInteraction.job_source.is_(None)
                    | (JobInteraction.job_source == "")
                    | JobInteraction.job_external_id.is_(None)
                    | (JobInteraction.job_external_id == "")
                )
            )
            .order_by(JobInteraction.id.asc())
            .all()
        )

        updated = 0
        unresolved = []

        for interaction in interactions:
            identity = extract_identity(interaction.job_url)

            if identity is None:
                unresolved.append(
                    (
                        interaction.id,
                        interaction.job_url,
                    )
                )
                continue

            interaction.job_source = identity[0]
            interaction.job_external_id = identity[1]
            updated += 1

        db.flush()

        all_interactions = (
            db.query(JobInteraction)
            .filter(
                JobInteraction.job_source.isnot(None),
                JobInteraction.job_source != "",
                JobInteraction.job_external_id.isnot(None),
                JobInteraction.job_external_id != "",
            )
            .order_by(JobInteraction.id.asc())
            .all()
        )

        seen = set()
        duplicate_ids = []

        for interaction in all_interactions:
            key = (
                interaction.user_id,
                interaction.job_source.strip().lower(),
                interaction.job_external_id.strip(),
                interaction.action,
            )

            if key in seen:
                duplicate_ids.append(interaction.id)
                db.delete(interaction)
                continue

            seen.add(key)

        print("updated:", updated)
        print("duplicate_ids_to_delete:", duplicate_ids)
        print("unresolved:", unresolved)

        db.commit()

        print("Backfill committed successfully.")

    except Exception:
        db.rollback()
        raise

    finally:
        db.close()


if __name__ == "__main__":
    main()
