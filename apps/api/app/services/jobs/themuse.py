import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


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
            timeout=10,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("results", []):

            title = item.get("name", "")

            if query.lower() not in title.lower():
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
                    url=item.get("refs", {}).get("landing_page", ""),
                    source="TheMuse",
                )
            )

        return jobs