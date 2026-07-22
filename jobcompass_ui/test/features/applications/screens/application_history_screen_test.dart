import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/features/applications/screens/application_history_screen.dart';
import 'package:jobcompass_ui/features/applications/services/application_api.dart';
import 'package:jobcompass_ui/core/localization/app_localizations.dart';
import 'package:jobcompass_ui/models/application.dart';
import 'package:jobcompass_ui/models/application_stats.dart';
import 'package:jobcompass_ui/models/job.dart';
import 'package:jobcompass_ui/providers/application_provider.dart';

class FakeApplicationApi implements ApplicationApi {
  @override
  final Dio dio = Dio();

  final List<Application> applications;
  final ApplicationStats stats;
  final Completer<Application>? updateCompleter;
  final Object? updateError;
  final List<Application> archivedApplications;

  int updateStatusCallCount = 0;
  int? receivedApplicationId;
  String? receivedStatus;

  int updateAnalyticsCallCount = 0;
  Map<String, int?>? receivedAnalyticsTotals;
  int archiveCallCount = 0;
  int unarchiveCallCount = 0;

  FakeApplicationApi({
    required this.applications,
    this.archivedApplications = const <Application>[],
    this.stats = const ApplicationStats(
      totalApplications: 1,
      totalScreenings: 0,
      totalInterviews: 0,
      totalOffers: 0,
      totalRejected: 0,
      activeProcesses: 1,
      screeningInProgress: 0,
      interviewInProgress: 0,
      technicalInterviewInProgress: 0,
      offerInProgress: 0,
    ),
    this.updateCompleter,
    this.updateError,
  });

  @override
  Future<List<Application>> fetchApplications() async {
    return applications;
  }

  @override
  Future<ApplicationStats> fetchStats() async {
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
  Future<Application> createApplication(Job job) {
    throw UnimplementedError();
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

    if (updateCompleter != null) {
      return updateCompleter!.future;
    }

    final current = applications.firstWhere(
      (application) => application.id == applicationId,
    );

    return Application(
      id: current.id,
      jobTitle: current.jobTitle,
      jobCompany: current.jobCompany,
      jobUrl: current.jobUrl,
      jobLocation: current.jobLocation,
      jobWorkFormat: current.jobWorkFormat,
      jobPublishedAt: current.jobPublishedAt,
      jobDescription: current.jobDescription,
      jobSource: current.jobSource,
      jobExternalId: current.jobExternalId,
      status: status,
      createdAt: current.createdAt,
      updatedAt: DateTime.utc(2026, 7, 12),
      archivedAt: current.archivedAt,
    );
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
      orElse: () => makeApplication(id: applicationId, status: 'applied'),
    );
  }

  @override
  Future<void> recordApplyInteraction(Job job) async {}
}

Application makeApplication({required int id, required String status}) {
  return Application(
    id: id,
    jobTitle: 'Senior QA Engineer $id',
    jobCompany: 'Acme',
    jobUrl: 'https://example.com/jobs/$id',
    jobLocation: 'Berlin',
    jobWorkFormat: 'Remote',
    jobPublishedAt: '2026-07-10T10:00:00Z',
    jobDescription: null,
    jobSource: 'adzuna',
    jobExternalId: '$id',
    status: status,
    createdAt: DateTime.utc(2026, 7, 10),
    updatedAt: DateTime.utc(2026, 7, 10),
    archivedAt: null,
  );
}

Future<void> pumpScreen(WidgetTester tester, FakeApplicationApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [applicationApiProvider.overrideWithValue(api)],
      child: const AppStrings(
        language: AppLanguage.english,
        child: MaterialApp(home: ApplicationHistoryScreen()),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows CRM dashboard metrics', (tester) async {
    final api = FakeApplicationApi(
      applications: [makeApplication(id: 1, status: 'interview')],
      stats: const ApplicationStats(
        totalApplications: 12,
        totalScreenings: 5,
        totalInterviews: 3,
        totalOffers: 1,
        totalRejected: 4,
        activeProcesses: 7,
        screeningInProgress: 2,
        interviewInProgress: 2,
        technicalInterviewInProgress: 1,
        offerInProgress: 1,
      ),
    );

    await pumpScreen(tester, api);

    expect(find.byKey(const ValueKey('application-dashboard')), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Total Applications'), findsOneWidget);
    expect(find.text('Total Screenings'), findsOneWidget);
    expect(find.text('Total Interviews'), findsOneWidget);
    expect(find.text('Total Offers'), findsOneWidget);
    expect(find.text('Total Rejected'), findsOneWidget);
    expect(find.text('Active Processes'), findsOneWidget);
    expect(find.text('Screening'), findsWidgets);
    expect(find.text('Interview'), findsWidgets);
    expect(find.text('Tech Interview'), findsWidgets);
    expect(find.text('Offer'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('application-metric-analytics-total-applications'),
        ),
        matching: find.text('12'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('application-metric-in-progress-active')),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );

    final analyticsCardKeys = [
      'application-metric-analytics-total-applications',
      'application-metric-analytics-total-screenings',
      'application-metric-analytics-total-interviews',
      'application-metric-analytics-total-offers',
      'application-metric-analytics-total-rejected',
    ];
    final analyticsCardTop = tester
        .getTopLeft(find.byKey(ValueKey(analyticsCardKeys.first)))
        .dy;

    for (final key in analyticsCardKeys.skip(1)) {
      expect(tester.getTopLeft(find.byKey(ValueKey(key))).dy, analyticsCardTop);
    }
  });

  testWidgets('edits Analytics totals without changing In Progress', (
    tester,
  ) async {
    final api = FakeApplicationApi(
      applications: [makeApplication(id: 1, status: 'screening')],
    );

    await pumpScreen(tester, api);

    await tester.tap(find.byKey(const ValueKey('analytics-edit-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('analytics-editor-dialog')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('analytics-total-applications-field')),
      '20',
    );
    await tester.enterText(
      find.byKey(const ValueKey('analytics-total-screenings-field')),
      '8',
    );
    await tester.tap(find.byKey(const ValueKey('analytics-save-button')));
    await tester.pumpAndSettle();

    expect(api.updateAnalyticsCallCount, 1);
    expect(api.receivedAnalyticsTotals, {
      'total_applications': 20,
      'total_screenings': 8,
      'total_interviews': 0,
      'total_offers': 0,
      'total_rejected': 0,
    });
    expect(find.byKey(const ValueKey('analytics-editor-dialog')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('application-metric-analytics-total-applications'),
        ),
        matching: find.text('20'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('application-metric-in-progress-active')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows all supported application statuses', (tester) async {
    final api = FakeApplicationApi(
      applications: [makeApplication(id: 1, status: 'applied')],
    );

    await pumpScreen(tester, api);

    await tester.scrollUntilVisible(
      find.text('Senior QA Engineer 1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('application-status-menu-1')));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('application-card-1'))).height,
      lessThanOrEqualTo(72),
    );

    for (final label in [
      'Applied',
      'Screening',
      'Interview',
      'Tech Interview',
      'Offer',
      'Rejected',
    ]) {
      expect(
        find.widgetWithText(CheckedPopupMenuItem<String>, label),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'updates status and shows progress only for selected application',
    (tester) async {
      final completer = Completer<Application>();

      final first = makeApplication(id: 1, status: 'applied');
      final second = makeApplication(id: 2, status: 'screening');

      final api = FakeApplicationApi(
        applications: [first, second],
        updateCompleter: completer,
      );

      await pumpScreen(tester, api);

      final firstApplicationTitle = find.text('Senior QA Engineer 1');

      await tester.scrollUntilVisible(
        firstApplicationTitle,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final firstStatusMenu = find.byKey(
        const ValueKey('application-status-menu-1'),
      );

      expect(firstStatusMenu, findsOneWidget);

      await tester.ensureVisible(firstStatusMenu);
      await tester.pumpAndSettle();
      await tester.tap(firstStatusMenu);
      await tester.pumpAndSettle();

      final interviewMenuItem = find.widgetWithText(
        CheckedPopupMenuItem<String>,
        'Interview',
      );

      expect(interviewMenuItem, findsOneWidget);

      await tester.tap(interviewMenuItem);
      await tester.pump();

      expect(api.updateStatusCallCount, 1);
      expect(api.receivedApplicationId, 1);
      expect(api.receivedStatus, 'interview');
      expect(
        find.byKey(const ValueKey('application-status-progress')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('application-status-menu-2')),
        findsOneWidget,
      );

      completer.complete(
        Application(
          id: first.id,
          jobTitle: first.jobTitle,
          jobCompany: first.jobCompany,
          jobUrl: first.jobUrl,
          jobLocation: first.jobLocation,
          jobWorkFormat: first.jobWorkFormat,
          jobPublishedAt: first.jobPublishedAt,
          jobDescription: first.jobDescription,
          jobSource: first.jobSource,
          jobExternalId: first.jobExternalId,
          status: 'interview',
          createdAt: first.createdAt,
          updatedAt: DateTime.utc(2026, 7, 12),
          archivedAt: first.archivedAt,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('application-status-menu-1')),
          matching: find.text('Interview'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('application-status-progress')),
        findsNothing,
      );
    },
  );

  testWidgets('shows error message when status update fails', (tester) async {
    final api = FakeApplicationApi(
      applications: [makeApplication(id: 1, status: 'applied')],
      updateError: StateError('request failed'),
    );

    await pumpScreen(tester, api);

    await tester.scrollUntilVisible(
      find.text('Senior QA Engineer 1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('application-status-menu-1')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'Offer'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Failed to update application status'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('application-status-menu-1')),
        matching: find.text('Applied'),
      ),
      findsOneWidget,
    );
  });
}
