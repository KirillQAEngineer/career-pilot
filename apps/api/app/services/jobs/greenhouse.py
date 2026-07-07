import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class GreenhouseProvider(JobProvider):

    URL = "https://boards-api.greenhouse.io/v1/boards"

    def search(
        self,
        query: str,
    ) -> list[Job]:

        jobs = []

        response = requests.get(
            self.URL,
            timeout=20,
        )

        response.raise_for_status()

        boards = response.json().get("boards", [])

        for board in boards[:50]:

            token = board.get("token")

            if not token:
                continue

            try:

                board_jobs = requests.get(
                    f"{self.URL}/{token}/jobs",
                    timeout=10,
                )

                if board_jobs.status_code != 200:
                    continue

                data = board_jobs.json()

                for item in data.get("jobs", []):

                    title = item.get("title", "")

                    if query.lower() not in title.lower():
                        continue

                    jobs.append(
                        Job(
                            title=title,
                            company=board.get("name", ""),
                            location="Remote",
                            url=item.get("absolute_url", ""),
                            source="Greenhouse",
                        )
                    )

            except Exception:
                continue

        return jobs