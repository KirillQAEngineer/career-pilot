import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class SuperJobProvider(JobProvider):

    URL = "https://api.superjob.ru/2.0/vacancies/"

    def search(self, query: str) -> list[Job]:

        headers = {
            "X-Api-App-Id": "YOUR_SUPERJOB_KEY",
        }

        response = requests.get(
            self.URL,
            headers=headers,
            params={
                "keyword": query,
                "count": 50,
            },
            timeout=10,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("objects", []):
            jobs.append(
                Job(
                    title=item.get("profession", ""),
                    company=item.get("firm_name", ""),
                    location=item.get("town", {}).get(
                        "title",
                        "Remote",
                    ),
                    url=item.get("link", ""),
                    source="SuperJob",
                    external_id=str(item.get("id", "")),
                    description=item.get("candidat"),
                    work_format=None,
                    published_at=(
                        str(item.get("date_published"))
                        if item.get("date_published")
                        else None
                    ),
                )
            )

        return jobs
