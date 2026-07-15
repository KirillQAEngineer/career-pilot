import 'package:dio/dio.dart';

import '../../../models/job.dart';

class JobsApi {
  JobsApi(this._dio);

  final Dio _dio;

  static const int _maxAttempts = 2;

  Future<List<Job>> fetchJobs({required bool forceRefresh}) async {
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _dio.get(
          '/jobs/feed',
          queryParameters: {'limit': 150, if (forceRefresh) 'refresh': true},
        );

        final data = response.data;

        if (data is! List) {
          throw const FormatException('Invalid jobs response: expected a list');
        }

        return data
            .map((item) => Job.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } on DioException catch (error) {
        if (attempt == _maxAttempts || !_isRetryable(error)) {
          rethrow;
        }

        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }

    throw StateError('Jobs request attempts exhausted');
  }

  bool _isRetryable(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
