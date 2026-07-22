import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/features/feed/models/job_filters.dart';
import 'package:jobcompass_ui/features/feed/services/job_filter_service.dart';
import 'package:jobcompass_ui/models/job.dart';
import 'package:jobcompass_ui/models/saved_job.dart';

void main() {
  const service = JobFilterService();

  Job makeJob({
    required String id,
    required String title,
    required String company,
    required String location,
    String? workFormat,
    DateTime? publishedAt,
  }) {
    return Job(
      title: title,
      company: company,
      location: location,
      url: 'https://example.com/jobs/$id',
      source: 'TestSource',
      externalId: id,
      description: null,
      score: 75,
      whyMatch: 'Test match reason',
      missingSkills: const <String>[],
      recommendation: 'good_fit',
      workFormat: workFormat,
      publishedAt: publishedAt,
    );
  }

  final now = DateTime.utc(2026, 7, 11, 12);

  late List<Job> jobs;

  setUp(() {
    jobs = [
      makeJob(
        id: '1',
        title: 'Senior QA Engineer',
        company: 'Acme',
        location: 'Berlin',
        workFormat: 'Remote',
        publishedAt: now.subtract(const Duration(hours: 12)),
      ),
      makeJob(
        id: '2',
        title: 'Backend Engineer',
        company: 'Beta',
        location: 'London',
        workFormat: 'Hybrid',
        publishedAt: now.subtract(const Duration(days: 3)),
      ),
      makeJob(
        id: '3',
        title: 'Python Developer',
        company: 'Gamma',
        location: 'Warsaw',
        workFormat: 'On-site',
        publishedAt: now.subtract(const Duration(days: 20)),
      ),
    ];
  });

  test('filters jobs by search query', () {
    final result = service.apply(
      jobs: jobs,
      filters: const JobFilters(query: 'qa'),
      now: now,
    );

    expect(result.map((job) => job.externalId), ['1']);
  });

  test('filters jobs by one work format', () {
    final result = service.apply(
      jobs: jobs,
      filters: const JobFilters(workFormats: {'Hybrid'}),
      now: now,
    );

    expect(result.map((job) => job.externalId), ['2']);
  });

  test('uses OR between selected work formats', () {
    final result = service.apply(
      jobs: jobs,
      filters: const JobFilters(workFormats: {'Remote', 'Hybrid'}),
      now: now,
    );

    expect(result.map((job) => job.externalId), ['1', '2']);
  });

  test('maps on-site jobs to Office filter', () {
    final result = service.apply(
      jobs: jobs,
      filters: const JobFilters(workFormats: {'Office'}),
      now: now,
    );

    expect(result.map((job) => job.externalId), ['3']);
  });

  test('filters jobs by publication date', () {
    final result = service.apply(
      jobs: jobs,
      filters: const JobFilters(
        publicationDate: PublicationDateFilter.last7Days,
      ),
      now: now,
    );

    expect(result.map((job) => job.externalId), ['1', '2']);
  });

  test('uses AND between work format and publication date', () {
    final result = service.apply(
      jobs: jobs,
      filters: const JobFilters(
        workFormats: {'Remote', 'Hybrid'},
        publicationDate: PublicationDateFilter.last24Hours,
      ),
      now: now,
    );

    expect(result.map((job) => job.externalId), ['1']);
  });

  test('excludes hidden jobs by stable key', () {
    final result = service.apply(
      jobs: jobs,
      filters: const JobFilters(),
      hiddenJobKeys: {jobs.first.stableKey},
      now: now,
    );

    expect(result.map((job) => job.externalId), ['2', '3']);
  });

  test('exposes exactly supported work formats', () {
    expect(service.workFormats(jobs), ['Remote', 'Hybrid', 'Office']);
  });

  test('filters saved jobs with the shared filter service', () {
    final savedJobs = [
      SavedJob(
        id: 10,
        title: 'Senior QA Engineer',
        company: 'Acme',
        url: 'https://example.com/saved/10',
        location: 'Berlin',
        workFormat: 'Remote',
        publishedAt: now.subtract(const Duration(hours: 6)),
        description: null,
        action: 'like',
        createdAt: now,
      ),
      SavedJob(
        id: 11,
        title: 'Backend Engineer',
        company: 'Beta',
        url: 'https://example.com/saved/11',
        location: 'London',
        workFormat: 'Hybrid',
        publishedAt: now.subtract(const Duration(days: 10)),
        description: null,
        action: 'like',
        createdAt: now,
      ),
    ];

    final result = service.apply(
      jobs: savedJobs,
      filters: const JobFilters(
        query: 'qa',
        workFormats: {'Remote'},
        publicationDate: PublicationDateFilter.last24Hours,
      ),
      now: now,
    );

    expect(result.map((job) => job.id), [10]);
  });

  test('clearStructuredFilters keeps search query', () {
    const filters = JobFilters(
      query: 'flutter',
      workFormats: {'Remote', 'Hybrid'},
      publicationDate: PublicationDateFilter.last7Days,
    );

    final result = filters.clearStructuredFilters();

    expect(result.query, 'flutter');
    expect(result.workFormats, isEmpty);
    expect(result.publicationDate, PublicationDateFilter.anyTime);
    expect(result.hasStructuredFilters, isFalse);
  });
}
