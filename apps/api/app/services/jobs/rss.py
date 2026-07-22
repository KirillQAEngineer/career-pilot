import html
import re
from dataclasses import dataclass
from xml.etree.ElementTree import Element

from defusedxml import ElementTree as ET

import requests

from app.schemas.job import Job
from app.services.jobs.base import JobProvider


@dataclass(frozen=True)
class RssFeed:
    url: str
    source: str


class RssJobProvider(JobProvider):
    feeds: tuple[RssFeed, ...] = ()

    def search(self, query: str) -> list[Job]:
        jobs: list[Job] = []

        for feed in self.feeds:
            response = requests.get(
                feed.url,
                headers={
                    "User-Agent": "JobCompass/1.0",
                    "Accept": "application/rss+xml, application/xml, text/xml",
                },
                timeout=4,
            )
            response.raise_for_status()

            jobs.extend(
                self._parse_feed(
                    feed.source,
                    response.content,
                )
            )

        return jobs

    def _parse_feed(
        self,
        source: str,
        content: bytes,
    ) -> list[Job]:
        root = ET.fromstring(content)
        jobs: list[Job] = []

        for item in root.findall(".//item"):
            job = self._parse_item(source, item)

            if job is not None:
                jobs.append(job)

        return jobs

    def _parse_item(
        self,
        source: str,
        item: Element,
    ) -> Job | None:
        raw_title = self._text(item, "title")
        link = self._text(item, "link") or self._text(item, "guid")

        if not raw_title or not link:
            return None

        title, company = self._split_title(raw_title)
        location = self._location(item)

        return Job(
            title=title,
            company=company,
            location=location,
            url=link,
            source=source,
            external_id=link,
            description=self._description(item),
            work_format="Remote",
            published_at=self._text(item, "pubDate"),
        )

    def _split_title(self, raw_title: str) -> tuple[str, str]:
        return raw_title.strip(), ""

    def _location(self, item: Element) -> str:
        return self._text(item, "region") or "Remote"

    def _description(self, item: Element) -> str | None:
        content = self._namespaced_text(
            item,
            "http://purl.org/rss/1.0/modules/content/",
            "encoded",
        )
        description = content or self._text(item, "description")

        if not description:
            return None

        return self._clean_html(description)

    def _text(
        self,
        item: Element,
        tag: str,
    ) -> str:
        value = item.findtext(tag) or ""

        return html.unescape(value).strip()

    def _namespaced_text(
        self,
        item: Element,
        namespace: str,
        tag: str,
    ) -> str:
        value = item.findtext(f"{{{namespace}}}{tag}") or ""

        return html.unescape(value).strip()

    def _clean_html(
        self,
        value: str,
    ) -> str:
        text = html.unescape(value)
        text = re.sub(r"<br\s*/?>", "\n", text, flags=re.IGNORECASE)
        text = re.sub(r"</p\s*>", "\n", text, flags=re.IGNORECASE)
        text = re.sub(r"<[^>]+>", " ", text)
        text = re.sub(r"[ \t]+", " ", text)
        text = re.sub(r"\n\s+", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)

        return text.strip()


class WeWorkRemotelyProvider(RssJobProvider):
    feeds = (
        RssFeed(
            url="https://weworkremotely.com/remote-jobs.rss",
            source="WeWorkRemotely",
        ),
    )

    def _split_title(self, raw_title: str) -> tuple[str, str]:
        title = raw_title.strip()

        if ":" not in title:
            return title, ""

        company, job_title = title.split(":", 1)

        return job_title.strip(), company.strip()


class JobspressoProvider(RssJobProvider):
    feeds = (
        RssFeed(
            url="https://jobspresso.co/feed/?post_type=job_listing",
            source="Jobspresso",
        ),
    )

    def _parse_item(
        self,
        source: str,
        item: Element,
    ) -> Job | None:
        job = super()._parse_item(source, item)

        if job is None:
            return None

        creator = self._namespaced_text(
            item,
            "http://purl.org/dc/elements/1.1/",
            "creator",
        )

        if creator:
            parts = [
                part.strip()
                for part in re.split(r"<br\s*/?>|⚲", creator)
                if part.strip()
            ]

            if parts:
                job.company = self._clean_html(parts[0])

            if len(parts) > 1:
                job.location = self._clean_html(parts[1])

        return job
