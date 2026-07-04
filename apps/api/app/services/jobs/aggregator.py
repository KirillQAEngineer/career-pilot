from app.schemas.job import Job

from app.services.jobs.remoteok import RemoteOKProvider
from app.services.jobs.remotive import RemotiveProvider
from app.services.jobs.jooble import JoobleProvider


class JobsAggregator:

    def __init__(self):
        self.providers = [
            RemoteOKProvider(),
            RemotiveProvider(),
            JoobleProvider(),
        ]

    def search(
        self,
        query: str,
    ) -> list[Job]:

            jobs = []

            for provider in self.providers:
                try:
                    provider_jobs = provider.search(query)

                    print(
                        f"{provider.__class__.__name__}: {len(provider_jobs)} jobs"
                    )
                    jobs.extend(provider_jobs)

                except Exception as error:
                    print(
                        f"{provider.__class__.__name__}: {error}"
                    )

            return self._remove_duplicates(jobs)
    
    def _remove_duplicates(
        self,
        jobs: list[Job],
    ) -> list[Job]:

        unique = {}
    
        for job in jobs:

            key = (
                job.title.strip().lower(),
                job.company.strip().lower(),
            )

            if key not in unique:
                unique[key] = job

        return list(unique.values())