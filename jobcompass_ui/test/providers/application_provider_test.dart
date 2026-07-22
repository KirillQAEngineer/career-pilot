import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/features/applications/services/application_api.dart';
import 'package:jobcompass_ui/models/application.dart';
import 'package:jobcompass_ui/models/application_stats.dart';
import 'package:jobcompass_ui/models/job.dart';
import 'package:jobcompass_ui/models/saved_job.dart';
import 'package:jobcompass_ui/providers/application_provider.dart';

class FakeApplicationApi extends ApplicationApi {
  FakeApplicationApi({
    required this.applications,
    this.archivedApplications = const <Application>[],
    this.stats = const ApplicationStats(
      totalApplications: 0,
      totalScreenings: 0,
      totalInterviews: 0,
      totalOffers: 0,
      totalRejected: 0,
      activeProcesses: 0,
      screeningInProgress: 0,
      interviewInProgress: 0,
      technicalInterviewInProgress: 0,
      offerInProgress: 0,
    ),
    this.updatedApplication,
    this.updateError,
  }) : super(Dio());

  final List<Application> applications;
  final List<Application> archivedApplications;
  final ApplicationStats stats;
  final Application? updatedApplication;
  final Object? updateError;

  int fetchStatsCallCount = 0;

  int updateAnalyticsCallCount = 0;
  Map<String, int?>? receivedAnalyticsTotals;

  int createApplicationCallCount = 0;
  Job? receivedCreatedJob;

  int updateStatusCallCount = 0;
  int? receivedApplicationId;
  String? receivedStatus;
  int archiveCallCount = 0;
  int unarchiveCallCount = 0;

  @override
  Future<List<Application>> fetchApplications() async {
    return applications;
  }

  @override
  Future<ApplicationStats> fetchStats() async {
    fetchStatsCallCount++;

    return stats;
  }

  @override
  Future<ApplicationStats> updateAnalyticsTotals(
    Map<String, int?> totals,
  ) async {
    updateAnalyticsCallCount++;
    receivedAnalyticsTotals = totals;

    return ApplicationStats(
      totalApplications:
          totals['total_applications'] ?? stats.totalApplications,
      totalScreenings: totals['total_screenings'] ?? stats.totalScreenings,
      totalInterviews: totals['total_interviews'] ?? stats.totalInterviews,
      totalOffers: totals['total_offers'] ?? stats.totalOffers,
      totalRejected: totals['total_rejected'] ?? stats.totalRejected,
      activeProcesses: stats.activeProcesses,
      screeningInProgress: stats.screeningInProgress,
      interviewInProgress: stats.interviewInProgress,
      technicalInterviewInProgress: stats.technicalInterviewInProgress,
      offerInProgress: stats.offerInProgress,
    );
  }

  @override
  Future<Application> createApplication(Job job) async {
    createApplicationCallCount++;
    receivedCreatedJob = job;

    return makeApplication(
      id: 99,
      status: 'applied',
      updatedAt: DateTime.utc(2026, 7, 13),
    );
  }

  @override
  Future<List<Application>> fetchArchivedApplications() async {
    return archivedApplications;
  }

  @override
  Future<Application> updateStatus({
    required int applicationId,
    required String status,
  }) async {
    updateStatusCallCount++;
    receivedApplicationId = applicationId;
    receivedStatus = status;

    if (updateError != null) {
      throw updateError!;
    }

    return updatedApplication!;
  }

  @override
  Future<Application> archiveApplication(int applicationId) async {
    archiveCallCount++;
    return applications.firstWhere(
      (application) => application.id == applicationId,
    );
  }

  @override
  Future<Application> unarchiveApplication(int applicationId) async {
    unarchiveCallCount++;
    return archivedApplications.firstWhere(
      (application) => application.id == applicationId,
      orElse: () => makeApplication(
        id: applicationId,
        status: 'applied',
        updatedAt: DateTime.utc(2026, 7, 13),
      ),
    );
  }

  @override
  Future<void> recordApplyInteraction(Job job) async {}
}

Application makeApplication({
  required int id,
  required String status,
  required DateTime updatedAt,
}) {
  return Application(
    id: id,
    jobTitle: 'QA Engineer $id',
    jobCompany: 'Company $id',
    jobUrl: 'https://example.com/jobs/$id',
    jobLocation: 'Remote',
    jobWorkFormat: 'Remote',
    jobPublishedAt: '2026-07-10T10:00:00Z',
    jobDescription: null,
    jobSource: 'test',
    jobExternalId: '$id',
    status: status,
    createdAt: DateTime.utc(2026, 7, 10),
    updatedAt: updatedAt,
    archivedAt: null,
  );
}

void main() {
  test('applySavedJob creates application with saved job identity', () async {
    final api = FakeApplicationApi(applications: const <Application>[]);

    final container = ProviderContainer(
      overrides: [applicationApiProvider.overrideWithValue(api)],
    );

    addTearDown(container.dispose);

    await container.read(applicationProvider.future);

    const savedJob = SavedJob(
      id: 10,
      title: 'Senior QA Engineer',
      company: 'Acme',
      url: 'https://example.com/jobs/qa-123',
      source: 'Adzuna',
      externalId: 'qa-123',
      location: 'Berlin',
      workFormat: 'Hybrid',
      publishedAt: null,
      description: null,
      action: 'like',
      createdAt: null,
    );

    final result = await container
        .read(applicationProvider.notifier)
        .applySavedJob(savedJob);

    final state = container.read(applicationProvider).requireValue;

    expect(result, isTrue);
    expect(api.createApplicationCallCount, 1);
    expect(api.receivedCreatedJob?.source, 'Adzuna');
    expect(api.receivedCreatedJob?.externalId, 'qa-123');
    expect(api.receivedCreatedJob?.title, 'Senior QA Engineer');
    expect(api.receivedCreatedJob?.company, 'Acme');
    expect(api.receivedCreatedJob?.url, savedJob.url);
    expect(state.single.id, 99);
  });

  test('applicationStatsProvider loads dashboard statistics', () async {
    final api = FakeApplicationApi(
      applications: const <Application>[],
      stats: const ApplicationStats(
        totalApplications: 9,
        totalScreenings: 4,
        totalInterviews: 2,
        totalOffers: 1,
        totalRejected: 3,
        activeProcesses: 5,
        screeningInProgress: 2,
        interviewInProgress: 1,
        technicalInterviewInProgress: 1,
        offerInProgress: 1,
      ),
    );

    final container = ProviderContainer(
      overrides: [applicationApiProvider.overrideWithValue(api)],
    );

    addTearDown(container.dispose);

    final stats = await container.read(applicationStatsProvider.future);

    expect(api.fetchStatsCallCount, 1);
    expect(stats.totalApplications, 9);
    expect(stats.totalScreenings, 4);
    expect(stats.totalInterviews, 2);
    expect(stats.totalOffers, 1);
    expect(stats.totalRejected, 3);
    expect(stats.activeProcesses, 5);
    expect(stats.screeningInProgress, 2);
    expect(stats.interviewInProgress, 1);
    expect(stats.technicalInterviewInProgress, 1);
    expect(stats.offerInProgress, 1);
  });

  test(
    'updateAnalyticsTotals stores backend response in provider state',
    () async {
      final api = FakeApplicationApi(applications: const <Application>[]);

      final container = ProviderContainer(
        overrides: [applicationApiProvider.overrideWithValue(api)],
      );

      addTearDown(container.dispose);

      await container.read(applicationStatsProvider.future);

      final result = await container
          .read(applicationStatsProvider.notifier)
          .updateAnalyticsTotals({
            'total_applications': 15,
            'total_screenings': 7,
          });

      final stats = container.read(applicationStatsProvider).requireValue;

      expect(result, isTrue);
      expect(api.updateAnalyticsCallCount, 1);
      expect(api.receivedAnalyticsTotals, {
        'total_applications': 15,
        'total_screenings': 7,
      });
      expect(stats.totalApplications, 15);
      expect(stats.totalScreenings, 7);
      expect(stats.activeProcesses, 0);
    },
  );

  test(
    'updateStatus replaces application with backend response and sorts state',
    () async {
      final first = makeApplication(
        id: 1,
        status: 'applied',
        updatedAt: DateTime.utc(2026, 7, 10),
      );

      final second = makeApplication(
        id: 2,
        status: 'screening',
        updatedAt: DateTime.utc(2026, 7, 11),
      );

      final updatedFirst = makeApplication(
        id: 1,
        status: 'interview',
        updatedAt: DateTime.utc(2026, 7, 12),
      );

      final api = FakeApplicationApi(
        applications: [second, first],
        updatedApplication: updatedFirst,
      );

      final container = ProviderContainer(
        overrides: [applicationApiProvider.overrideWithValue(api)],
      );

      addTearDown(container.dispose);

      await container.read(applicationProvider.future);

      final result = await container
          .read(applicationProvider.notifier)
          .updateStatus(applicationId: first.id, status: 'interview');

      final state = container.read(applicationProvider).requireValue;

      expect(result, isTrue);
      expect(api.updateStatusCallCount, 1);
      expect(api.receivedApplicationId, first.id);
      expect(api.receivedStatus, 'interview');
      expect(state.map((application) => application.id), [1, 2]);
      expect(state.first.status, 'interview');
      expect(state.first.updatedAt, DateTime.utc(2026, 7, 12));
    },
  );

  test('updateStatus keeps current state when API request fails', () async {
    final application = makeApplication(
      id: 1,
      status: 'applied',
      updatedAt: DateTime.utc(2026, 7, 10),
    );

    final api = FakeApplicationApi(
      applications: [application],
      updateError: StateError('request failed'),
    );

    final container = ProviderContainer(
      overrides: [applicationApiProvider.overrideWithValue(api)],
    );

    addTearDown(container.dispose);

    await container.read(applicationProvider.future);

    final result = await container
        .read(applicationProvider.notifier)
        .updateStatus(applicationId: application.id, status: 'offer');

    final state = container.read(applicationProvider).requireValue;

    expect(result, isFalse);
    expect(api.updateStatusCallCount, 1);
    expect(state, same(api.applications));
    expect(state.single.status, 'applied');
  });
}
