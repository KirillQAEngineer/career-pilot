import time

import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.greenhouse_companies import GREENHOUSE_COMPANIES
from app.services.jobs.search_terms import matches_search_terms


class GreenhouseProvider(JobProvider):

    URL = "https://boards-api.greenhouse.io/v1/boards"
    TIME_BUDGET_SECONDS = 5.0

    def search(
        self,
        query: str,
    ) -> list[Job]:

        jobs = []
        deadline = time.monotonic() + self.TIME_BUDGET_SECONDS

        for company_name, token in GREENHOUSE_COMPANIES:
            if time.monotonic() > deadline:
                break

            if not token:
                continue

            try:

                board_jobs = requests.get(
                    f"{self.URL}/{token}/jobs",
                    timeout=3,
                )

                if board_jobs.status_code != 200:
                    continue

                data = board_jobs.json()

                for item in data.get("jobs", []):

                    title = item.get("title", "")

                    searchable = " ".join(
                        [
                            title,
                            item.get("content") or "",
                            company_name,
                        ]
                    )

                    if not matches_search_terms(
                        searchable,
                        query,
                    ):
                        continue

                    location = "Remote"
                    locations = item.get("location")

                    if isinstance(locations, dict):
                        location = locations.get("name") or location

                    jobs.append(
                        Job(
                            title=title,
                            company=company_name,
                            location=location,
                            url=item.get("absolute_url", ""),
                            source="Greenhouse",
                            external_id=str(item.get("id", "")),
                            description=item.get("content"),
                            work_format=None,
                            published_at=item.get("updated_at"),
                        )
                    )

            except Exception:
                continue

        return jobs
