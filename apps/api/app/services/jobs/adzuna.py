from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

from app.core.config import settings
from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class AdzunaProvider(JobProvider):
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
        response = requests.get(
            f"https://api.adzuna.com/v1/api/jobs/us/search/{page}",
            params={
                "app_id": settings.adzuna_app_id,
                "app_key": settings.adzuna_app_key,
                "results_per_page": self.RESULTS_PER_PAGE,
                "what": query,
                "content-type": "application/json",
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("results", []):
            jobs.append(
                Job(
                    title=item.get("title", ""),
                    company=item.get("company", {}).get(
                        "display_name",
                        "",
                    ),
                    location=item.get("location", {}).get(
                        "display_name",
                        "",
                    ),
                    url=item.get("redirect_url", ""),
                    source="Adzuna",
                    external_id=str(item.get("id", "")),
                    description=item.get("description"),
                    work_format=None,
                    published_at=item.get("created"),
                )
            )

        return jobs
