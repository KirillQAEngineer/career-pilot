from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

from app.core.config import settings
from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class JoobleProvider(JobProvider):
    PAGES = 6
    RESULTS_PER_PAGE = 50

    def search(
        self,
        query: str,
    ) -> list[Job]:

        jobs: list[Job] = []

        with ThreadPoolExecutor(max_workers=self.PAGES) as executor:
            futures = [
                executor.submit(self._fetch_page, query, page)
                for page in range(1, self.PAGES + 1)
            ]

            for future in as_completed(futures):
                try:
                    jobs.extend(future.result())
                except Exception:
                    continue

        return jobs

    def _fetch_page(self, query: str, page: int) -> list[Job]:
        response = requests.post(
            f"https://jooble.org/api/{settings.jooble_api_key}",
            json={
                "keywords": query,
                "location": "",
                "page": page,
                "ResultOnPage": self.RESULTS_PER_PAGE,
                "companysearch": False,
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("jobs", []):
            jobs.append(
                Job(
                    title=item.get("title", ""),
                    company=item.get("company", ""),
                    location=item.get("location", "Remote"),
                    url=item.get("link", ""),
                    source="Jooble",
                    external_id=str(item.get("id", "")),
                    description=item.get("snippet"),
                    work_format=None,
                    published_at=item.get("updated"),
                )
            )

        return jobs
