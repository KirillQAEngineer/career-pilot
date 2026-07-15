from urllib.parse import urlsplit

import requests
from bs4 import BeautifulSoup

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


class GeekJobProvider(JobProvider):

    URL = "https://geekjob.ru/vacancies"

    def search(self, query: str) -> list[Job]:

        response = requests.get(
            self.URL,
            params={"qs": query},
            headers={"User-Agent": "JobCompass/1.0"},
            timeout=4,
        )
        response.raise_for_status()

        soup = BeautifulSoup(
            response.text,
            "html.parser",
        )

        jobs = []

        for card in soup.select(".collection-item"):
            title = card.select_one(".vacancy-name .title")
            company = card.select_one(".company-name")

            if not title:
                continue

            title_text = title.text.strip()

            job_url = "https://geekjob.ru" + title.get("href", "")

            external_id = urlsplit(job_url).path.rstrip("/")

            jobs.append(
                Job(
                    title=title_text,
                    company=(
                        company.text.strip()
                        if company
                        else ""
                    ),
                    location="RU",
                    url=job_url,
                    source="GeekJob",
                    external_id=external_id,
                )
            )

        return jobs
