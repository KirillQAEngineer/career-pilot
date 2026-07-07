import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class LeverProvider(JobProvider):

    BASE_URL = "https://api.lever.co/v0/postings"

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
    ]

    def search(self, query: str) -> list[Job]:

        jobs = []
        query_lower = query.lower()

        for company in self.COMPANIES:

            try:
                response = requests.get(
                    f"{self.BASE_URL}/{company}",
                    params={"mode": "json"},
                    timeout=10,
                )

                if response.status_code != 200:
                    continue

                data = response.json()

                for item in data:

                    title = item.get("text", "")
                    location = item.get("categories", {}).get("location", "Remote")

                    jobs.append(
                        Job(
                            title=title,
                            company=company,
                            location=location,
                            url=item.get("hostedUrl", ""),
                            source="Lever",
                        )
                    )

            except Exception:
                continue

        return jobs