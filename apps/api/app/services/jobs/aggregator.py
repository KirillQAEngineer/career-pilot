from app.schemas.job import Job

from concurrent.futures import ThreadPoolExecutor, as_completed

from app.services.jobs.remoteok import RemoteOKProvider
from app.services.jobs.remotive import RemotiveProvider
from app.services.jobs.jooble import JoobleProvider
from app.services.jobs.themuse import TheMuseProvider
from app.services.jobs.adzuna import AdzunaProvider
from app.services.jobs.rss import (
    JobspressoProvider,
    WeWorkRemotelyProvider,
)

# NEW RU sources 
from app.services.jobs.superjob import SuperJobProvider
from app.services.jobs.zarplata import ZarplataProvider
from app.services.jobs.geekjob import GeekJobProvider

from app.services.jobs.logger import JobLogger
from app.services.jobs.quality_pipeline import JobQualityPipeline
from app.services.jobs.metadata_normalizer import JobMetadataNormalizer


class JobsAggregator:

    def __init__(self):

        self.providers = [
            # GLOBAL
            RemoteOKProvider(),
            RemotiveProvider(),
            WeWorkRemotelyProvider(),
            JobspressoProvider(),
            JoobleProvider(),
            TheMuseProvider(),
            AdzunaProvider(),

            # RU
            SuperJobProvider(),
            ZarplataProvider(),
            GeekJobProvider(),
        ]

        self.logger = JobLogger()
        self.pipeline = JobQualityPipeline()
        self.metadata_normalizer = JobMetadataNormalizer()
    def search(self, query: str) -> list[Job]:

        jobs = []

        with ThreadPoolExecutor(max_workers=len(self.providers)) as executor:

            futures = {
                executor.submit(provider.search, query): provider
                for provider in self.providers
            }

            for future in as_completed(futures):

                provider = futures[future]
                name = provider.__class__.__name__

                self.logger.start_provider(name)

                try:
                    result = future.result()

                    self.logger.success(
                        name,
                        len(result),
                        0.0
                    )

                    jobs.extend(result)

                except Exception as e:
                    self.logger.error(name, e)

        deduped = self._remove_duplicates(jobs)

        normalized = self.metadata_normalizer.normalize(
            deduped,
        )

        cleaned = self.pipeline.clean(
            normalized,
            query=query,
        )

        return cleaned

    def _remove_duplicates(self, jobs: list[Job]) -> list[Job]:

        unique = {}

        for job in jobs:

            key = (
                job.title.strip().lower(),
                job.company.strip().lower(),
            )

            if key not in unique:
                unique[key] = job

        return list(unique.values())
