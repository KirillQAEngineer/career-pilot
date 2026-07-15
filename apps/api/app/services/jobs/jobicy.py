import html
import re

import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.search_terms import detect_role_group


class JobicyProvider(JobProvider):
    URL = "https://jobicy.com/api/v2/remote-jobs"

    INDUSTRY_BY_ROLE_GROUP = {
        "qa": "qa-testing",
        "backend": "dev",
        "frontend": "dev",
        "fullstack": "dev",
        "mobile": "dev",
        "data": "data-science",
        "devops": "devops",
    }

    def search(
        self,
        query: str,
    ) -> list[Job]:
        params = {
            "count": 100,
        }

        role_group = detect_role_group(query)
        industry = self.INDUSTRY_BY_ROLE_GROUP.get(
            role_group or "",
        )

        if industry:
            params["industry"] = industry
        elif query:
            params["tag"] = query

        response = requests.get(
            self.URL,
            params=params,
            headers={
                "User-Agent": "JobCompass/1.0",
                "Accept": "application/json",
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()
        jobs: list[Job] = []

        for item in data.get("jobs", []):
            job_id = item.get("id") or item.get("jobSlug")
            description = self._clean_html(
                item.get("jobDescription")
                or item.get("jobExcerpt")
            )

            jobs.append(
                Job(
                    title=item.get("jobTitle", ""),
                    company=item.get("companyName", ""),
                    location=item.get("jobGeo", "Remote"),
                    url=item.get("url", ""),
                    source="Jobicy",
                    external_id=str(job_id),
                    description=description,
                    work_format="Remote",
                    published_at=item.get("pubDate"),
                )
            )

        return jobs

    def _clean_html(
        self,
        value: str | None,
    ) -> str | None:
        if not value:
            return None

        text = html.unescape(value)
        text = re.sub(r"<br\s*/?>", "\n", text, flags=re.IGNORECASE)
        text = re.sub(r"</p\s*>", "\n", text, flags=re.IGNORECASE)
        text = re.sub(r"<[^>]+>", " ", text)
        text = re.sub(r"[ \t]+", " ", text)
        text = re.sub(r"\n\s+", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)

        return text.strip()
