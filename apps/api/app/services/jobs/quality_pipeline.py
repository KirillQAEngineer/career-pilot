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

    ROLE_GROUPS = {
        "qa": {
            "qa",
            "quality assurance",
            "quality engineer",
            "quality analyst",
            "quality specialist",
            "software tester",
            "test engineer",
            "test automation",
            "automation engineer",
            "sdet",
        },
        "backend": {
            "backend",
            "back-end",
            "back end",
            "server-side",
        },
        "frontend": {
            "frontend",
            "front-end",
            "front end",
            "react developer",
            "vue developer",
            "angular developer",
        },
        "fullstack": {
            "fullstack",
            "full-stack",
            "full stack",
        },
        "mobile": {
            "mobile developer",
            "ios developer",
            "android developer",
            "flutter developer",
            "react native developer",
        },
        "data": {
            "data engineer",
            "data scientist",
            "data analyst",
            "machine learning engineer",
            "ml engineer",
        },
        "devops": {
            "devops",
            "site reliability engineer",
            "sre",
            "platform engineer",
            "cloud engineer",
        },
    }

    QUERY_ROLE_HINTS = {
        "qa": "qa",
        "quality assurance": "qa",
        "quality engineer": "qa",
        "software tester": "qa",
        "test engineer": "qa",
        "sdet": "qa",
        "backend": "backend",
        "back-end": "backend",
        "frontend": "frontend",
        "front-end": "frontend",
        "fullstack": "fullstack",
        "full-stack": "fullstack",
        "full stack": "fullstack",
        "mobile": "mobile",
        "ios": "mobile",
        "android": "mobile",
        "flutter": "mobile",
        "data engineer": "data",
        "data scientist": "data",
        "data analyst": "data",
        "machine learning": "data",
        "devops": "devops",
        "sre": "devops",
    }

    def clean(
        self,
        jobs: list[Job],
        query: str | None = None,
    ) -> list[Job]:

        cleaned = []

        role_group = self._detect_query_role_group(query)

        for job in jobs:

            self._normalize_job(job)

            if not self._is_valid(job):
                continue

            if (
                role_group is not None
                and not self._is_relevant_to_role(
                    job,
                    role_group,
                )
            ):
                continue

            cleaned.append(job)

        return cleaned

    def _normalize_job(self, job: Job) -> None:
        job.title = self._normalize_text(job.title)
        job.company = self._normalize_text(job.company)
        job.location = self._normalize_text(job.location)

    def _is_valid(self, job: Job) -> bool:

        if not job.title:
            return False

        title = job.title.strip().lower()

        if len(title) < 3:
            return False

        for pattern in self.BAD_PATTERNS:
            if re.fullmatch(pattern, title):
                return False

        return True

    def _detect_query_role_group(
        self,
        query: str | None,
    ) -> str | None:

        if not query:
            return None

        normalized_query = self._normalize_text(query).lower()

        ordered_hints = sorted(
            self.QUERY_ROLE_HINTS.items(),
            key=lambda item: len(item[0]),
            reverse=True,
        )

        for hint, role_group in ordered_hints:
            if self._contains_phrase(
                normalized_query,
                hint,
            ):
                return role_group

        return None

    def _is_relevant_to_role(
        self,
        job: Job,
        role_group: str,
    ) -> bool:

        title = job.title.lower()

        role_keywords = self.ROLE_GROUPS.get(
            role_group,
            set(),
        )

        return any(
            self._contains_phrase(title, keyword)
            for keyword in role_keywords
        )

    def _contains_phrase(
        self,
        text: str,
        phrase: str,
    ) -> bool:

        pattern = (
            r"(?<!\w)"
            + re.escape(phrase)
            + r"(?!\w)"
        )

        return re.search(
            pattern,
            text,
            flags=re.IGNORECASE,
        ) is not None

    def _normalize_text(self, text: str) -> str:

        if not text:
            return ""

        text = text.strip()
        text = re.sub(r"\s+", " ", text)
        text = text.replace("&amp;", "&")

        return text
