import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.search_terms import matches_search_terms


class TheMuseProvider(JobProvider):

    def search(
        self,
        query: str,
    ) -> list[Job]:

        response = requests.get(
            "https://www.themuse.com/api/public/jobs",
            params={
                "page": 0,
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("results", []):
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
                continue

            company = ""

            if item.get("company"):
                company = item["company"].get("name", "")

            location = "Remote"

            locations = item.get("locations", [])

            if locations:
                location = locations[0].get("name", "Remote")

            jobs.append(
                Job(
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
            )

        return jobs
