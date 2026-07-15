import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/features/feed/services/jobs_api.dart';
import 'package:jobcompass_ui/models/job.dart';
import 'package:jobcompass_ui/providers/jobs_provider.dart';

class FakeJobsApi extends JobsApi {
  FakeJobsApi({required this.initialJobs, this.refreshError}) : super(Dio());

  final List<Job> initialJobs;
  final Object? refreshError;

  int refreshCalls = 0;

  @override
  Future<List<Job>> fetchJobs({required bool forceRefresh}) async {
    if (!forceRefresh) {
      return initialJobs;
    }

    refreshCalls++;

    if (refreshError != null) {
      throw refreshError!;
    }

    return initialJobs;
  }
}

void main() {
  final job = Job(
    title: 'QA Engineer',
    company: 'Acme',
    location: 'Remote',
    url: 'https://example.com/jobs/1',
    source: 'Example',
    externalId: '1',
    score: 80,
    whyMatch: 'Good match',
    missingSkills: const [],
    recommendation: 'Apply',
  );

  test('failed refresh preserves the current vacancy list', () async {
    final api = FakeJobsApi(
      initialJobs: [job],
      refreshError: Exception('temporary backend error'),
    );
    final container = ProviderContainer(
      overrides: [jobsApiProvider.overrideWithValue(api)],
    );

    addTearDown(container.dispose);

    await container.read(jobsProvider.future);

    final refreshed = await container.read(jobsProvider.notifier).refresh();

    expect(refreshed, isFalse);
    expect(api.refreshCalls, 1);
    expect(container.read(jobsProvider).requireValue, [job]);
  });
}
