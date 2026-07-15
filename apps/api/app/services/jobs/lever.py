from concurrent.futures import (
    ThreadPoolExecutor,
    TimeoutError as FuturesTimeoutError,
    as_completed,
)

import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.search_terms import matches_search_terms


class LeverProvider(JobProvider):

    BASE_URL = "https://api.lever.co/v0/postings"
    TIME_BUDGET_SECONDS = 5.5
    MAX_WORKERS = 12

    COMPANIES = [
        "lever",
        "netflix",
        "coinbase",
        "shopify",
        "plaid",
        "dropbox",
        "square",
        "palantir",
        "vercel",
        "datadog",
        "gitlab",
        "automattic",
        "zapier",
        "webflow",
        "docker",
        "postman",
        "render",
        "trellis",
        "rivr",
        "revealtech",
        "lingarogroup",
        "Fliff",
        "cartrawler",
        "seranbio",
        "airalo",
    ]

    def search(self, query: str) -> list[Job]:

        jobs: list[Job] = []
        executor = ThreadPoolExecutor(max_workers=self.MAX_WORKERS)
        futures = [
            executor.submit(self._fetch_company, company, query)
            for company in self.COMPANIES
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
        company: str,
        query: str,
    ) -> list[Job]:
        response = requests.get(
            f"{self.BASE_URL}/{company}",
            params={"mode": "json"},
            timeout=4,
        )

        if response.status_code != 200:
            return []

        jobs: list[Job] = []

        for item in response.json():
            title = item.get("text", "")
            location = item.get("categories", {}).get(
                "location",
                "Remote",
            )
            searchable = " ".join(
                [
                    title,
                    item.get("descriptionPlain") or "",
                    company,
                ]
            )

            if not matches_search_terms(searchable, query):
                continue

            created_at = item.get("createdAt")

            jobs.append(
                Job(
                    title=title,
                    company=company,
                    location=location,
                    url=item.get("hostedUrl", ""),
                    source="Lever",
                    external_id=str(
                        item.get("id", item.get("hostedUrl", ""))
                    ),
                    description=item.get("descriptionPlain"),
                    work_format=None,
                    published_at=(
                        str(created_at)
                        if created_at is not None
                        else None
                    ),
                )
            )

        return jobs
