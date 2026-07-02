from app.services.jobs.remoteok import RemoteOKProvider


def get_jobs_provider():
    return RemoteOKProvider()