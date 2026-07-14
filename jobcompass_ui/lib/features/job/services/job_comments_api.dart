import 'package:dio/dio.dart';

import 'package:jobcompass_ui/models/job_comment.dart';

class JobCommentsApi {
  const JobCommentsApi(this.dio);

  final Dio dio;

  Future<List<JobComment>> fetchComments() async {
    final response = await dio.get('/jobs/comments');
    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) => JobComment.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<JobComment> saveComment({
    required String jobSource,
    required String jobExternalId,
    required String comment,
  }) async {
    final response = await dio.put(
      '/jobs/comments',
      data: {
        'job_source': jobSource,
        'job_external_id': jobExternalId,
        'comment': comment,
      },
    );

    return JobComment.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
