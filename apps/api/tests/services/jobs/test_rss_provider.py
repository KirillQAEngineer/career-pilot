from app.services.jobs.rss import (
    JobspressoProvider,
    WeWorkRemotelyProvider,
)


def test_weworkremotely_parses_company_title_and_description():
    provider = WeWorkRemotelyProvider()

    jobs = provider._parse_feed(
        "WeWorkRemotely",
        b"""
        <rss>
          <channel>
            <item>
              <title>Acme: Senior QA Engineer</title>
              <region>Anywhere in the World</region>
              <description><![CDATA[
                <p>Build reliable test automation.</p>
                <p>To apply: <a href="https://example.com/job">Apply</a></p>
              ]]></description>
              <pubDate>Tue, 14 Jul 2026 03:03:10 +0000</pubDate>
              <guid>https://example.com/job</guid>
              <link>https://example.com/job</link>
            </item>
          </channel>
        </rss>
        """,
    )

    assert len(jobs) == 1
    assert jobs[0].title == "Senior QA Engineer"
    assert jobs[0].company == "Acme"
    assert jobs[0].location == "Anywhere in the World"
    assert jobs[0].source == "WeWorkRemotely"
    assert jobs[0].external_id == "https://example.com/job"
    assert "Build reliable test automation." in jobs[0].description
    assert "<p>" not in jobs[0].description


def test_jobspresso_parses_creator_company_and_location():
    provider = JobspressoProvider()

    content = """
        <rss xmlns:dc="http://purl.org/dc/elements/1.1/"
             xmlns:content="http://purl.org/rss/1.0/modules/content/">
          <channel>
            <item>
              <title>Full-Stack Engineer</title>
              <link>https://jobspresso.co/job/full-stack-engineer/</link>
              <dc:creator><![CDATA[Paperpile<br>⚲&nbsp;Worldwide]]></dc:creator>
              <pubDate>Wed, 29 Apr 2026 09:28:03 +0000</pubDate>
              <description><![CDATA[<p>React and TypeScript role.</p>]]></description>
            </item>
          </channel>
        </rss>
        """.encode()

    jobs = provider._parse_feed(
        "Jobspresso",
        content,
    )

    assert len(jobs) == 1
    assert jobs[0].title == "Full-Stack Engineer"
    assert jobs[0].company == "Paperpile"
    assert jobs[0].location == "Worldwide"
    assert jobs[0].source == "Jobspresso"
    assert jobs[0].url == "https://jobspresso.co/job/full-stack-engineer/"
