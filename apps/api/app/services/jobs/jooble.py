import requests

from app.core.config import settings
from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class JoobleProvider(JobProvider):

    def search(
        self,
        query: str,
    ) -> list[Job]:

        response = requests.post(
            f"https://jooble.org/api/{settings.jooble_api_key}",
            json={
                "keywords": query,
                "location": "",
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("jobs", []):
            jobs.append(
                Job(
                    title=item.get("title", ""),
                    company=item.get("company", ""),
                    location=item.get("location", "Remote"),
                    url=item.get("link", ""),
                    source="Jooble",
                    external_id=str(item.get("id", "")),
                    description=item.get("snippet"),
                    work_format=None,
                    published_at=item.get("updated"),
                )
            )

        return jobs
