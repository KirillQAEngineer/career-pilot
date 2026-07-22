import time
from concurrent.futures import (
    ThreadPoolExecutor,
    TimeoutError as FuturesTimeoutError,
    as_completed,
)
from threading import Lock

from app.schemas.job import Job
from app.core.config import settings

from app.services.jobs.remoteok import RemoteOKProvider
from app.services.jobs.remotive import RemotiveProvider
from app.services.jobs.jooble import JoobleProvider
from app.services.jobs.themuse import TheMuseProvider
from app.services.jobs.adzuna import AdzunaProvider
from app.services.jobs.arbeitnow import ArbeitnowProvider
from app.services.jobs.greenhouse import GreenhouseProvider
from app.services.jobs.jobicy import JobicyProvider
from app.services.jobs.lever import LeverProvider
from app.services.jobs.rss import (
    JobspressoProvider,
    WeWorkRemotelyProvider,
)

# NEW RU sources
from app.services.jobs.geekjob import GeekJobProvider

from app.services.jobs.logger import JobLogger
from app.services.jobs.quality_pipeline import JobQualityPipeline
from app.services.jobs.metadata_normalizer import JobMetadataNormalizer


class JobsAggregator:
    CACHE_TTL_SECONDS = 1800
    SEARCH_TIMEOUT_SECONDS = 8.0
    MAX_WORKERS = 16

    def __init__(self):
        self._cache: dict[str, tuple[float, list[Job]]] = {}
        self._cache_lock = Lock()

        self.providers = [
            # GLOBAL
            RemoteOKProvider(),
            RemotiveProvider(),
            JobicyProvider(),
            ArbeitnowProvider(),
            WeWorkRemotelyProvider(),
            JobspressoProvider(),
            GreenhouseProvider(),
            LeverProvider(),
            TheMuseProvider(),
            GeekJobProvider(),
        ]

        if settings.jooble_api_key:
            self.providers.append(JoobleProvider())

        if settings.adzuna_app_id and settings.adzuna_app_key:
            self.providers.append(AdzunaProvider())

        self.logger = JobLogger()
        self.pipeline = JobQualityPipeline()
        self.metadata_normalizer = JobMetadataNormalizer()

    def search(
        self,
        query: str,
        force_refresh: bool = False,
    ) -> list[Job]:
        cache_key = query.strip().lower()
        cached_jobs = self._get_cached(cache_key)

        if cached_jobs is not None and not force_refresh:
            return cached_jobs

        jobs = []

        executor = ThreadPoolExecutor(
            max_workers=min(
                len(self.providers),
                self.MAX_WORKERS,
            )
        )

        futures = {}
        started_at = {}

        for provider in self.providers:
            name = provider.__class__.__name__
            self.logger.start_provider(name)
            future = executor.submit(provider.search, query)
            futures[future] = provider
            started_at[future] = time.monotonic()

        try:
            for future in as_completed(
                futures,
                timeout=self.SEARCH_TIMEOUT_SECONDS,
            ):
                provider = futures[future]
                name = provider.__class__.__name__

                try:
                    result = future.result()
                    self.logger.success(
                        name,
                        len(result),
                        time.monotonic() - started_at[future],
                    )
                    jobs.extend(result)

                except Exception as e:
                    self.logger.error(name, e)

        except FuturesTimeoutError as e:
            self.logger.error(
                "JobsAggregator",
                e,
            )

        finally:
            for future in futures:
                if not future.done():
                    future.cancel()

            executor.shutdown(
                wait=False,
                cancel_futures=True,
            )

        if force_refresh and cached_jobs:
            jobs.extend(cached_jobs)

        deduped = self._remove_duplicates(jobs)

        normalized = self.metadata_normalizer.normalize(
            deduped,
        )

        cleaned = self.pipeline.clean(
            normalized,
            query=query,
        )

        if cleaned:
            self._set_cached(
                cache_key,
                cleaned,
            )

        return cleaned

    def _get_cached(
        self,
        cache_key: str,
    ) -> list[Job] | None:
        with self._cache_lock:
            cached = self._cache.get(cache_key)

            if cached is None:
                return None

            cached_at, jobs = cached

            if time.monotonic() - cached_at > self.CACHE_TTL_SECONDS:
                self._cache.pop(cache_key, None)
                return None

            return list(jobs)

    def _set_cached(
        self,
        cache_key: str,
        jobs: list[Job],
    ) -> None:
        with self._cache_lock:
            self._cache[cache_key] = (
                time.monotonic(),
                list(jobs),
            )

    def _remove_duplicates(self, jobs: list[Job]) -> list[Job]:

        unique = {}

        for job in jobs:

            key = (
                job.title.strip().lower(),
                job.company.strip().lower(),
                job.location.strip().lower(),
            )

            if key not in unique:
                unique[key] = job

        return list(unique.values())
