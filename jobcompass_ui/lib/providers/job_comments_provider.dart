import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jobcompass_ui/core/network/api_client.dart';
import 'package:jobcompass_ui/features/job/services/job_comments_api.dart';
import 'package:jobcompass_ui/models/job_comment.dart';

final jobCommentsApiProvider = Provider<JobCommentsApi>(
  (ref) => JobCommentsApi(ApiClient.dio),
);

class JobCommentsNotifier extends AsyncNotifier<Map<String, JobComment>> {
  JobCommentsApi get _api => ref.read(jobCommentsApiProvider);

  @override
  Future<Map<String, JobComment>> build() async {
    final comments = await _api.fetchComments();

    return {
      for (final comment in comments)
        if (comment.comment.isNotEmpty) comment.stableKey: comment,
    };
  }

  Future<bool> saveComment({
    required String jobSource,
    required String jobExternalId,
    required String comment,
  }) async {
    try {
      final updatedComment = await _api.saveComment(
        jobSource: jobSource,
        jobExternalId: jobExternalId,
        comment: comment,
      );

      final key = JobComment.buildStableKey(jobSource, jobExternalId);
      final currentComments = state.value ?? const <String, JobComment>{};

      if (updatedComment.comment.isEmpty) {
        state = AsyncData({
          for (final entry in currentComments.entries)
            if (entry.key != key) entry.key: entry.value,
        });
      } else {
        state = AsyncData({...currentComments, key: updatedComment});
      }

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final jobCommentsProvider =
    AsyncNotifierProvider<JobCommentsNotifier, Map<String, JobComment>>(
      JobCommentsNotifier.new,
    );
