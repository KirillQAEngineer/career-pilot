import re

from app.schemas.job import Job


class JobQualityPipeline:

    BAD_PATTERNS = [
        r"^jobs?$",
        r"^heading$",
        r"^template$",
        r"^all positions$",
        r"^spontaneous application$",
        r"^f$",
        r"^test role$",
    ]

    def clean(self, jobs: list[Job]) -> list[Job]:

        cleaned = []

        for job in jobs:

            if not self._is_valid(job):
                continue

            job.title = self._normalize_text(job.title)
            job.company = self._normalize_text(job.company)

            cleaned.append(job)

        return cleaned

    def _is_valid(self, job: Job) -> bool:

        if not job.title or len(job.title.strip()) < 3:
            return False

        title = job.title.strip().lower()

        for pattern in self.BAD_PATTERNS:
            if re.match(pattern, title):
                return False

        # remove obvious junk
        if len(title) < 5:
            return False

        return True

    def _normalize_text(self, text: str) -> str:

        if not text:
            return ""

        text = text.strip()
        text = re.sub(r"\s+", " ", text)
        text = text.replace("&amp;", "&")

        return text