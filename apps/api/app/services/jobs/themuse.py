from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.search_terms import matches_search_terms


class TheMuseProvider(JobProvider):
    PAGES = 12

    def search(
        self,
        query: str,
    ) -> list[Job]:

        jobs = []

        with ThreadPoolExecutor(max_workers=self.PAGES) as executor:
            futures = [
                executor.submit(self._fetch_page, page)
                for page in range(self.PAGES)
            ]

            for future in as_completed(futures):
                try:
                    items = future.result()
                except Exception:
                    continue

                for item in items:
                    job = self._parse_job(item, query)

                    if job is not None:
                        jobs.append(job)

        return jobs

    def _fetch_page(self, page: int) -> list[dict]:
        response = requests.get(
            "https://www.themuse.com/api/public/jobs",
            params={"page": page},
            timeout=4,
        )

        response.raise_for_status()

        return response.json().get("results", [])

    def _parse_job(
        self,
        item: dict,
        query: str,
    ) -> Job | None:
        title = item.get("name", "")

        searchable = " ".join(
            [
                title,
                item.get("contents") or "",
            ]
        )

        if not matches_search_terms(
            searchable,
            query,
        ):
            return None

        company = ""

        if item.get("company"):
            company = item["company"].get("name", "")

        location = "Remote"

        locations = item.get("locations", [])

        if locations:
            location = locations[0].get("name", "Remote")

        return Job(
            title=title,
            company=company,
            location=location,
            url=item.get("refs", {}).get(
                "landing_page",
                "",
            ),
            source="TheMuse",
            external_id=str(item.get("id", "")),
            description=item.get("contents"),
            work_format=None,
            published_at=item.get("publication_date"),
        )
