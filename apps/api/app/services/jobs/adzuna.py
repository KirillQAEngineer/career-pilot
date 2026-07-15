import requests

from app.core.config import settings
from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class AdzunaProvider(JobProvider):

    def search(
        self,
        query: str,
    ) -> list[Job]:

        response = requests.get(
            "https://api.adzuna.com/v1/api/jobs/us/search/1",
            params={
                "app_id": settings.adzuna_app_id,
                "app_key": settings.adzuna_app_key,
                "results_per_page": 50,
                "what": query,
                "content-type": "application/json",
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data.get("results", []):
            jobs.append(
                Job(
                    title=item.get("title", ""),
                    company=item.get("company", {}).get(
                        "display_name",
                        "",
                    ),
                    location=item.get("location", {}).get(
                        "display_name",
                        "",
                    ),
                    url=item.get("redirect_url", ""),
                    source="Adzuna",
                    external_id=str(item.get("id", "")),
                    description=item.get("description"),
                    work_format=None,
                    published_at=item.get("created"),
                )
            )

        return jobs
