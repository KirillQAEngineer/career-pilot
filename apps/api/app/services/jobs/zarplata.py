import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class ZarplataProvider(JobProvider):

    URL = "https://api.zarplata.ru/vacancies"

    def search(self, query: str) -> list[Job]:

        response = requests.get(
            self.URL,
            params={
                "text": query,
                "limit": 50,
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("items", []):
            jobs.append(
                Job(
                    title=item.get("title", ""),
                    company=item.get("company", ""),
                    location=item.get("area", "Remote"),
                    url=item.get("url", ""),
                    source="Zarplata",
                    external_id=str(item.get("id", "")),
                    description=item.get("description"),
                    work_format=None,
                    published_at=item.get("published_at"),
                )
            )

        return jobs
