import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class RemotiveProvider(JobProvider):

    URL = "https://remotive.com/api/remote-jobs"

    def search(
        self,
        query: str,
    ) -> list[Job]:

        response = requests.get(
            self.URL,
            params={
                "search": query,
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("jobs", []):
            jobs.append(
                Job(
                    title=item["title"],
                    company=item["company_name"],
                    location=item["candidate_required_location"],
                    url=item["url"],
                    source="Remotive",
                    external_id=str(item.get("id", "")),
                    description=item.get("description"),
                    work_format="Remote",
                    published_at=item.get("publication_date"),
                )
            )

        return jobs
