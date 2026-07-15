import html
import re

import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.search_terms import matches_search_terms


class ArbeitnowProvider(JobProvider):
    URL = "https://www.arbeitnow.com/api/job-board-api"

    def search(
        self,
        query: str,
    ) -> list[Job]:
        response = requests.get(
            self.URL,
            headers={
                "User-Agent": "JobCompass/1.0",
                "Accept": "application/json",
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()
        jobs: list[Job] = []

        for item in data.get("data", []):
            title = item.get("title", "")
            tags = item.get("tags") or []
            description = self._clean_html(
                item.get("description"),
            )

            searchable = " ".join(
                [
                    title,
                    description or "",
                    " ".join(tags),
                ]
            )

            if not matches_search_terms(
                searchable,
                query,
            ):
                continue

            slug = item.get("slug") or item.get("url") or title

            created_at = item.get("created_at")

            jobs.append(
                Job(
                    title=title,
                    company=item.get("company_name", ""),
                    location=item.get("location", "Germany"),
                    url=item.get("url", ""),
                    source="Arbeitnow",
                    external_id=str(slug),
                    description=description,
                    work_format=(
                        "Remote"
                        if item.get("remote")
                        else None
                    ),
                    published_at=(
                        str(created_at)
                        if created_at is not None
                        else None
                    ),
                )
            )

        return jobs

    def _clean_html(
        self,
        value: str | None,
    ) -> str | None:
        if not value:
            return None

        text = html.unescape(value)
        text = re.sub(r"<br\s*/?>", "\n", text, flags=re.IGNORECASE)
        text = re.sub(r"</p\s*>", "\n", text, flags=re.IGNORECASE)
        text = re.sub(r"<[^>]+>", " ", text)
        text = re.sub(r"[ \t]+", " ", text)
        text = re.sub(r"\n\s+", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)

        return text.strip()
