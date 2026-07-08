import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class RemoteOKProvider(JobProvider):

    def search(
        self,
        query: str,
    ) -> list[Job]:

        response = requests.get(
            "https://remoteok.com/api",
            headers={
                "User-Agent": "CareerPilot",
            },
            timeout=20,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data[1:]:
            title = item.get("position", "")

            if query.lower() not in title.lower():
                continue

            jobs.append(
                Job(
                    title=title,
                    company=item.get("company", ""),
                    location=item.get("location", "Remote"),
                    url=item.get("url", ""),
                    source="RemoteOK",
                    external_id=str(item.get("id", "")),
                )
            )

        return jobs
