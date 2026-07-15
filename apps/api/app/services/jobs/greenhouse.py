from concurrent.futures import (
    ThreadPoolExecutor,
    TimeoutError as FuturesTimeoutError,
    as_completed,
)

import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.greenhouse_companies import GREENHOUSE_COMPANIES
from app.services.jobs.search_terms import matches_search_terms


class GreenhouseProvider(JobProvider):

    URL = "https://boards-api.greenhouse.io/v1/boards"
    TIME_BUDGET_SECONDS = 5.5
    MAX_WORKERS = 12

    def search(
        self,
        query: str,
    ) -> list[Job]:

        jobs: list[Job] = []
        executor = ThreadPoolExecutor(max_workers=self.MAX_WORKERS)
        futures = [
            executor.submit(
                self._fetch_company,
                company_name,
                token,
                query,
            )
            for company_name, token in GREENHOUSE_COMPANIES
            if token
        ]

        try:
            for future in as_completed(
                futures,
                timeout=self.TIME_BUDGET_SECONDS,
            ):
                try:
                    jobs.extend(future.result())
                except Exception:
                    continue
        except FuturesTimeoutError:
            pass
        finally:
            for future in futures:
                if not future.done():
                    future.cancel()

            executor.shutdown(wait=False, cancel_futures=True)

        return jobs

    def _fetch_company(
        self,
        company_name: str,
        token: str,
        query: str,
    ) -> list[Job]:
        response = requests.get(
            f"{self.URL}/{token}/jobs",
            timeout=4,
        )

        if response.status_code != 200:
            return []

        jobs: list[Job] = []

        for item in response.json().get("jobs", []):
            title = item.get("title", "")
            searchable = " ".join(
                [
                    title,
                    item.get("content") or "",
                    company_name,
                ]
            )

            if not matches_search_terms(searchable, query):
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

        return jobs
