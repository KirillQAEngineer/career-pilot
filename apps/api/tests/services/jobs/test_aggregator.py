import time

from app.schemas.job import Job
from app.services.jobs.aggregator import JobsAggregator


def make_job(
    title: str = "QA Engineer",
    external_id: str = "1",
) -> Job:
    return Job(
        title=title,
        company="Acme",
        location="Remote",
        url=f"https://example.com/jobs/{external_id}",
        source="TestProvider",
        external_id=external_id,
    )


class FastProvider:
    def __init__(self):
        self.calls = 0

    def search(self, query: str):
        self.calls += 1
        return [make_job()]


class SlowProvider:
    def search(self, query: str):
        time.sleep(0.2)
        return [make_job("QA Engineer", "slow")]


def test_aggregator_caches_jobs_by_query():
    provider = FastProvider()
    aggregator = JobsAggregator()
    aggregator.providers = [provider]

    first = aggregator.search("QA Engineer")
    second = aggregator.search("QA Engineer")

    assert len(first) == 1
    assert len(second) == 1
    assert provider.calls == 1


def test_aggregator_returns_partial_results_before_slow_provider_finishes():
    aggregator = JobsAggregator()
    aggregator.providers = [
        FastProvider(),
        SlowProvider(),
    ]
    aggregator.SEARCH_TIMEOUT_SECONDS = 0.05

    started_at = time.monotonic()
    jobs = aggregator.search("QA Engineer")
    elapsed = time.monotonic() - started_at

    assert [job.external_id for job in jobs] == ["1"]
    assert elapsed < 0.15
