import time

import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.search_terms import matches_search_terms


class LeverProvider(JobProvider):

    BASE_URL = "https://api.lever.co/v0/postings"
    TIME_BUDGET_SECONDS = 5.0

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
    ]

    def search(self, query: str) -> list[Job]:

        jobs = []
        deadline = time.monotonic() + self.TIME_BUDGET_SECONDS

        for company in self.COMPANIES:
            if time.monotonic() > deadline:
                break

            try:
                response = requests.get(
                    f"{self.BASE_URL}/{company}",
                    params={"mode": "json"},
                    timeout=3,
                )

                if response.status_code != 200:
                    continue

                data = response.json()

                for item in data:

                    title = item.get("text", "")
                    location = item.get("categories", {}).get("location", "Remote")

                    searchable = " ".join(
                        [
                            title,
                            item.get("descriptionPlain") or "",
                            company,
                        ]
                    )

                    if not matches_search_terms(
                        searchable,
                        query,
                    ):
                        continue

                    created_at = item.get("createdAt")

                    jobs.append(
                        Job(
                            title=title,
                            company=company,
                            location=location,
                            url=item.get("hostedUrl", ""),
                            source="Lever",
                            external_id=str(item.get("id", item.get("hostedUrl", ""))),
                            description=item.get("descriptionPlain"),
                            work_format=None,
                            published_at=(
                                str(created_at)
                                if created_at is not None
                                else None
                            ),
                        )
                    )

            except Exception:
                continue

        return jobs
