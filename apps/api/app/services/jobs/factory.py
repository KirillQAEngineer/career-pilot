from app.services.jobs.aggregator import JobsAggregator

_jobs_provider = JobsAggregator()


def get_jobs_provider():
    return _jobs_provider
