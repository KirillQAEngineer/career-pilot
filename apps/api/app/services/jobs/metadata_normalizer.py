from datetime import datetime, timezone
from email.utils import parsedate_to_datetime


class JobMetadataNormalizer:

    REMOTE_KEYWORDS = (
        "remote",
        "worldwide",
        "anywhere",
        "work from home",
        "wfh",
    )

    HYBRID_KEYWORDS = (
        "hybrid",
    )

    ONSITE_KEYWORDS = (
        "on-site",
        "onsite",
        "on site",
        "office-based",
        "office based",
    )

    def normalize_work_format(
        self,
        work_format: str | None,
        location: str,
        title: str,
    ) -> str | None:

        values = (
            work_format or "",
            location or "",
            title or "",
        )

        normalized = " ".join(values).lower()

        if any(
            keyword in normalized
            for keyword in self.HYBRID_KEYWORDS
        ):
            return "Hybrid"

        if any(
            keyword in normalized
            for keyword in self.REMOTE_KEYWORDS
        ):
            return "Remote"

        if any(
            keyword in normalized
            for keyword in self.ONSITE_KEYWORDS
        ):
            return "On-site"

        return None

    def normalize_published_at(
        self,
        published_at,
    ) -> str | None:

        if published_at is None:
            return None

        if isinstance(
            published_at,
            (int, float),
        ):
            return self._normalize_timestamp(
                published_at,
            )

        value = str(published_at).strip()

        if not value:
            return None

        if value.isdigit():
            return self._normalize_timestamp(
                int(value),
            )

        try:
            normalized = value

            if normalized.endswith("Z"):
                normalized = (
                    normalized[:-1]
                    + "+00:00"
                )

            parsed = datetime.fromisoformat(
                normalized,
            )

            if parsed.tzinfo is None:
                parsed = parsed.replace(
                    tzinfo=timezone.utc,
                )

            return self._to_utc_iso(parsed)

        except (
            ValueError,
            OverflowError,
            OSError,
        ):
            pass

        try:
            parsed = parsedate_to_datetime(value)

            if parsed.tzinfo is None:
                parsed = parsed.replace(
                    tzinfo=timezone.utc,
                )

            return self._to_utc_iso(parsed)

        except (
            TypeError,
            ValueError,
            OverflowError,
            OSError,
        ):
            return None

    def _normalize_timestamp(
        self,
        timestamp: int | float,
    ) -> str | None:

        try:
            value = float(timestamp)

            if value > 10_000_000_000:
                value = value / 1000

            parsed = datetime.fromtimestamp(
                value,
                tz=timezone.utc,
            )

            return self._to_utc_iso(parsed)

        except (
            ValueError,
            OverflowError,
            OSError,
        ):
            return None

    def _to_utc_iso(
        self,
        value: datetime,
    ) -> str:

        return (
            value.astimezone(timezone.utc)
            .isoformat()
            .replace("+00:00", "Z")
        )

    def normalize_job(
        self,
        job,
    ):

        job.work_format = self.normalize_work_format(
            job.work_format,
            job.location,
            job.title,
        )

        job.published_at = self.normalize_published_at(
            job.published_at,
        )

        return job

    def normalize(
        self,
        jobs,
    ):

        return [
            self.normalize_job(job)
            for job in jobs
        ]
