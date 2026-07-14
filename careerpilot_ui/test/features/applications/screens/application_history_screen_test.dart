import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:careerpilot_ui/features/applications/screens/application_history_screen.dart';
import 'package:careerpilot_ui/features/applications/services/application_api.dart';
import 'package:careerpilot_ui/models/application.dart';
import 'package:careerpilot_ui/models/application_stats.dart';
import 'package:careerpilot_ui/models/job.dart';
import 'package:careerpilot_ui/providers/application_provider.dart';

class FakeApplicationApi implements ApplicationApi {
  @override
  final Dio dio = Dio();

  final List<Application> applications;
  final ApplicationStats stats;
  final Completer<Application>? updateCompleter;
  final Object? updateError;

  int updateStatusCallCount = 0;
  int? receivedApplicationId;
  String? receivedStatus;

  FakeApplicationApi({
    required this.applications,
    this.stats = const ApplicationStats(
      totalApplications: 1,
      activeProcesses: 1,
      interviews: 0,
      offers: 0,
      rejected: 0,
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
  Future<Application> createApplication(Job job) {
    throw UnimplementedError();
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
      userId: current.userId,
      jobTitle: current.jobTitle,
      jobCompany: current.jobCompany,
      jobUrl: current.jobUrl,
      jobLocation: current.jobLocation,
      jobWorkFormat: current.jobWorkFormat,
      jobPublishedAt: current.jobPublishedAt,
      jobSource: current.jobSource,
      jobExternalId: current.jobExternalId,
      status: status,
      createdAt: current.createdAt,
      updatedAt: DateTime.utc(2026, 7, 12),
    );
  }
}

Application makeApplication({required int id, required String status}) {
  return Application(
    id: id,
    userId: 1,
    jobTitle: 'Senior QA Engineer $id',
    jobCompany: 'Acme',
    jobUrl: 'https://example.com/jobs/$id',
    jobLocation: 'Berlin',
    jobWorkFormat: 'Remote',
    jobPublishedAt: '2026-07-10T10:00:00Z',
    jobSource: 'adzuna',
    jobExternalId: '$id',
    status: status,
    createdAt: DateTime.utc(2026, 7, 10),
    updatedAt: DateTime.utc(2026, 7, 10),
  );
}

Future<void> pumpScreen(WidgetTester tester, FakeApplicationApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [applicationApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: ApplicationHistoryScreen()),
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
        activeProcesses: 7,
        interviews: 3,
        offers: 1,
        rejected: 4,
      ),
    );

    await pumpScreen(tester, api);

    expect(find.byKey(const ValueKey('application-dashboard')), findsOneWidget);
    expect(find.text('Total Applications'), findsOneWidget);
    expect(find.text('Active Processes'), findsOneWidget);
    expect(find.text('Interviews'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('shows all supported application statuses', (tester) async {
    final api = FakeApplicationApi(
      applications: [makeApplication(id: 1, status: 'applied')],
    );

    await pumpScreen(tester, api);

    await tester.ensureVisible(
      find.byKey(const ValueKey('application-status-menu-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('application-status-menu-1')));
    await tester.pumpAndSettle();

    expect(find.text('Applied'), findsWidgets);
    expect(find.text('Screening'), findsOneWidget);
    expect(find.text('Interview'), findsOneWidget);
    expect(find.text('Technical Interview'), findsOneWidget);
    expect(find.text('Offer'), findsOneWidget);
    expect(find.text('Rejected'), findsWidgets);
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
          userId: first.userId,
          jobTitle: first.jobTitle,
          jobCompany: first.jobCompany,
          jobUrl: first.jobUrl,
          jobLocation: first.jobLocation,
          jobWorkFormat: first.jobWorkFormat,
          jobPublishedAt: first.jobPublishedAt,
          jobSource: first.jobSource,
          jobExternalId: first.jobExternalId,
          status: 'interview',
          createdAt: first.createdAt,
          updatedAt: DateTime.utc(2026, 7, 12),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Interview'), findsOneWidget);
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

    await tester.ensureVisible(
      find.byKey(const ValueKey('application-status-menu-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('application-status-menu-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Offer').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Failed to update application status'), findsOneWidget);
    expect(find.text('Applied'), findsOneWidget);
  });
}
