from app.services.jobs.arbeitnow import ArbeitnowProvider
from app.services.jobs.adzuna import AdzunaProvider
from app.services.jobs.jobicy import JobicyProvider
from app.services.jobs.jooble import JoobleProvider


class FakeResponse:
    def __init__(self, data):
        self._data = data

    def raise_for_status(self):
        return None

    def json(self):
        return self._data


def test_jobicy_provider_parses_remote_jobs(monkeypatch):
    captured = {}

    def fake_get(url, params=None, headers=None, timeout=None):
        captured["url"] = url
        captured["params"] = params

        return FakeResponse(
            {
                "jobs": [
                    {
                        "id": 123,
                        "url": "https://jobicy.com/jobs/123",
                        "jobTitle": "QA Automation Engineer",
                        "companyName": "Acme",
                        "jobGeo": "Europe",
                        "jobDescription": "<p>Build API tests.</p>",
                        "pubDate": "2026-07-15T08:00:00+00:00",
                    }
                ]
            }
        )

    monkeypatch.setattr(
        "app.services.jobs.jobicy.requests.get",
        fake_get,
    )

    jobs = JobicyProvider().search("Senior QA Engineer")

    assert captured["url"] == JobicyProvider.URL
    assert captured["params"]["industry"] == "qa-testing"
    assert jobs[0].title == "QA Automation Engineer"
    assert jobs[0].company == "Acme"
    assert jobs[0].source == "Jobicy"
    assert jobs[0].external_id == "123"
    assert jobs[0].work_format == "Remote"
    assert jobs[0].description == "Build API tests."


def test_arbeitnow_provider_filters_and_parses_jobs(monkeypatch):
    def fake_get(url, params=None, headers=None, timeout=None):
        if params != {"page": 1}:
            return FakeResponse({"data": []})

        return FakeResponse(
            {
                "data": [
                    {
                        "slug": "qa-engineer-1",
                        "company_name": "Acme",
                        "title": "QA Engineer",
                        "description": "<p>Manual and API testing.</p>",
                        "remote": True,
                        "url": "https://arbeitnow.com/jobs/qa-engineer-1",
                        "tags": ["Remote", "QA"],
                        "location": "Berlin",
                        "created_at": 1784046628,
                    },
                    {
                        "slug": "marketing-manager-1",
                        "company_name": "MarketCo",
                        "title": "Marketing Manager",
                        "description": "<p>Ads and content.</p>",
                        "remote": True,
                        "url": "https://arbeitnow.com/jobs/marketing-manager-1",
                        "tags": ["Marketing"],
                        "location": "Berlin",
                        "created_at": 1784046628,
                    },
                ]
            }
        )

    monkeypatch.setattr(
        "app.services.jobs.arbeitnow.requests.get",
        fake_get,
    )

    jobs = ArbeitnowProvider().search("Senior QA Engineer")

    assert len(jobs) == 1
    assert jobs[0].title == "QA Engineer"
    assert jobs[0].company == "Acme"
    assert jobs[0].source == "Arbeitnow"
    assert jobs[0].work_format == "Remote"
    assert jobs[0].description == "Manual and API testing."


def test_adzuna_reads_six_pages_of_results(monkeypatch):
    pages = set()

    def fake_get(url, params=None, timeout=None):
        page = int(url.rstrip("/").split("/")[-1])
        pages.add(page)
        return FakeResponse(
            {
                "results": [
                    {
                        "id": page,
                        "title": f"QA Engineer {page}",
                        "company": {"display_name": "Acme"},
                        "location": {"display_name": "Remote"},
                        "redirect_url": f"https://example.com/{page}",
                    }
                ]
            }
        )

    monkeypatch.setattr("app.services.jobs.adzuna.requests.get", fake_get)

    jobs = AdzunaProvider().search("QA Engineer")

    assert pages == {1, 2, 3, 4, 5, 6}
    assert len(jobs) == 6


def test_jooble_reads_six_pages_of_results(monkeypatch):
    pages = set()

    def fake_post(url, json=None, timeout=None):
        page = json["page"]
        pages.add(page)
        return FakeResponse(
            {
                "jobs": [
                    {
                        "id": page,
                        "title": f"QA Engineer {page}",
                        "company": "Acme",
                        "location": "Remote",
                        "link": f"https://example.com/{page}",
                    }
                ]
            }
        )

    monkeypatch.setattr("app.services.jobs.jooble.requests.post", fake_post)

    jobs = JoobleProvider().search("QA Engineer")

    assert pages == {1, 2, 3, 4, 5, 6}
    assert len(jobs) == 6
