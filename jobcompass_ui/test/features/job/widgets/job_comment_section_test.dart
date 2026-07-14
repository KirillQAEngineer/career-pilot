import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/features/job/services/job_comments_api.dart';
import 'package:jobcompass_ui/features/job/widgets/job_comment_section.dart';
import 'package:jobcompass_ui/core/localization/app_localizations.dart';
import 'package:jobcompass_ui/models/job_comment.dart';
import 'package:jobcompass_ui/providers/job_comments_provider.dart';

class FakeJobCommentsApi extends JobCommentsApi {
  FakeJobCommentsApi() : super(Dio());

  int saveCallCount = 0;

  @override
  Future<List<JobComment>> fetchComments() async {
    return const <JobComment>[];
  }

  @override
  Future<JobComment> saveComment({
    required String jobSource,
    required String jobExternalId,
    required String comment,
  }) async {
    saveCallCount++;

    return JobComment(
      jobSource: jobSource.toLowerCase(),
      jobExternalId: jobExternalId,
      comment: comment,
      updatedAt: comment.isEmpty ? null : DateTime.utc(2026, 7, 14),
    );
  }
}

Future<void> pumpSharedComments(
  WidgetTester tester,
  FakeJobCommentsApi api,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [jobCommentsApiProvider.overrideWithValue(api)],
      child: const AppStrings(
        language: AppLanguage.english,
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                JobCommentSection(jobSource: 'Adzuna', jobExternalId: '123'),
                JobCommentSection(jobSource: 'adzuna', jobExternalId: '123'),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('synchronizes comment across cards with same identity', (
    tester,
  ) async {
    final api = FakeJobCommentsApi();

    await pumpSharedComments(tester, api);

    expect(find.text('Add comment'), findsNWidgets(2));

    await tester.tap(find.text('Add comment').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-comment-dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('job-comment-field')),
      'Recruiter expects a reply on Friday',
    );
    await tester.tap(find.byKey(const ValueKey('job-comment-save-button')));
    await tester.pumpAndSettle();

    expect(api.saveCallCount, 1);
    expect(find.text('Recruiter expects a reply on Friday'), findsNWidgets(2));
  });

  testWidgets('deletes comment from every matching card', (tester) async {
    final api = FakeJobCommentsApi();

    await pumpSharedComments(tester, api);

    await tester.tap(find.text('Add comment').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('job-comment-field')),
      'Temporary note',
    );
    await tester.tap(find.byKey(const ValueKey('job-comment-save-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Temporary note').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('job-comment-delete-button')));
    await tester.pumpAndSettle();

    expect(api.saveCallCount, 2);
    expect(find.text('Temporary note'), findsNothing);
    expect(find.text('Add comment'), findsNWidgets(2));
  });
}
