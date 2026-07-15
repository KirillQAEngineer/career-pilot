import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider
from app.services.jobs.search_terms import matches_search_terms


class RemoteOKProvider(JobProvider):

    def search(
        self,
        query: str,
    ) -> list[Job]:

        response = requests.get(
            "https://remoteok.com/api",
            headers={
                "User-Agent": "JobCompass",
            },
            timeout=4,
        )

        response.raise_for_status()

        data = response.json()

        jobs = []

        for item in data[1:]:
            title = item.get("position", "")

            searchable = " ".join(
                [
                    title,
                    item.get("description") or "",
                    item.get("company") or "",
                    " ".join(item.get("tags") or []),
                ]
            )

            if not matches_search_terms(
                searchable,
                query,
            ):
                continue

            published_at = (
                item.get("date")
                or item.get("epoch")
            )

            jobs.append(
                Job(
                    title=title,
                    company=item.get("company", ""),
                    location=item.get("location", "Remote"),
                    url=item.get("url", ""),
                    source="RemoteOK",
                    external_id=str(item.get("id", "")),
                    description=item.get("description"),
                    work_format="Remote",
                    published_at=(
                        str(published_at)
                        if published_at is not None
                        else None
                    ),
                )
            )

        return jobs
