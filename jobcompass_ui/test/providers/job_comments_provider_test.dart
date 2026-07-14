import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/features/job/services/job_comments_api.dart';
import 'package:jobcompass_ui/models/job_comment.dart';
import 'package:jobcompass_ui/providers/job_comments_provider.dart';

class FakeJobCommentsApi extends JobCommentsApi {
  FakeJobCommentsApi({this.comments = const <JobComment>[]}) : super(Dio());

  final List<JobComment> comments;

  int saveCallCount = 0;
  String? receivedSource;
  String? receivedExternalId;
  String? receivedComment;

  @override
  Future<List<JobComment>> fetchComments() async {
    return comments;
  }

  @override
  Future<JobComment> saveComment({
    required String jobSource,
    required String jobExternalId,
    required String comment,
  }) async {
    saveCallCount++;
    receivedSource = jobSource;
    receivedExternalId = jobExternalId;
    receivedComment = comment;

    return JobComment(
      jobSource: jobSource.toLowerCase(),
      jobExternalId: jobExternalId,
      comment: comment,
      updatedAt: comment.isEmpty ? null : DateTime.utc(2026, 7, 14),
    );
  }
}

void main() {
  test('loads comments by normalized stable identity', () async {
    final api = FakeJobCommentsApi(
      comments: const [
        JobComment(
          jobSource: 'adzuna',
          jobExternalId: '123',
          comment: 'Existing note',
          updatedAt: null,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [jobCommentsApiProvider.overrideWithValue(api)],
    );

    addTearDown(container.dispose);

    final comments = await container.read(jobCommentsProvider.future);

    expect(comments['adzuna::123']?.comment, 'Existing note');
  });

  test('saving and deleting comment updates shared provider state', () async {
    final api = FakeJobCommentsApi();
    final container = ProviderContainer(
      overrides: [jobCommentsApiProvider.overrideWithValue(api)],
    );

    addTearDown(container.dispose);

    await container.read(jobCommentsProvider.future);

    final saveResult = await container
        .read(jobCommentsProvider.notifier)
        .saveComment(
          jobSource: 'Adzuna',
          jobExternalId: '123',
          comment: 'Follow up tomorrow',
        );

    expect(saveResult, isTrue);
    expect(api.saveCallCount, 1);
    expect(api.receivedSource, 'Adzuna');
    expect(api.receivedExternalId, '123');
    expect(api.receivedComment, 'Follow up tomorrow');
    expect(
      container.read(jobCommentsProvider).requireValue['adzuna::123']?.comment,
      'Follow up tomorrow',
    );

    final deleteResult = await container
        .read(jobCommentsProvider.notifier)
        .saveComment(jobSource: 'adzuna', jobExternalId: '123', comment: '');

    expect(deleteResult, isTrue);
    expect(
      container.read(jobCommentsProvider).requireValue,
      isNot(contains('adzuna::123')),
    );
  });
}
