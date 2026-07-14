import 'package:dio/dio.dart';

import 'package:careerpilot_ui/models/application.dart';
import 'package:careerpilot_ui/models/application_stats.dart';
import 'package:careerpilot_ui/models/job.dart';

class ApplicationApi {
  const ApplicationApi(this.dio);

  final Dio dio;

  Future<List<Application>> fetchApplications() async {
    final response = await dio.get('/applications');

    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) =>
              Application.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ApplicationStats> fetchStats() async {
    final response = await dio.get('/applications/stats');

    return ApplicationStats.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Application> createApplication(Job job) async {
    final response = await dio.post(
      '/applications',
      data: {
        'job_title': job.title,
        'job_company': job.company,
        'job_url': job.url,
        'job_location': job.location.isEmpty ? null : job.location,
        'job_work_format': job.workFormat,
        'job_published_at': job.publishedAt?.toUtc().toIso8601String(),
        'job_source': job.source,
        'job_external_id': job.externalId,
      },
    );

    return Application.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Application> updateStatus({
    required int applicationId,
    required String status,
  }) async {
    final response = await dio.patch(
      '/applications/$applicationId/status',
      data: {'status': status},
    );

    return Application.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
