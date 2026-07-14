import 'package:dio/dio.dart';

import '../../../models/job.dart';

class JobDetailsApi {
  const JobDetailsApi(this.dio);

  final Dio dio;

  Map<String, dynamic> _payload(Job job) {
    return {
      'job': {
        'title': job.title,
        'company': job.company,
        'location': job.location,
        'url': job.url,
        'source': job.source,
        'external_id': job.externalId,
        'work_format': job.workFormat,
        'published_at': job.publishedAt?.toUtc().toIso8601String(),
        'description': job.description,
      },
    };
  }

  Future<int> fetchMatch(Job job) async {
    final response = await dio.post('/jobs/match', data: _payload(job));

    return (response.data['match'] as num?)?.round() ?? 0;
  }

  Future<({List<String> skills, String summary})> fetchRequirements(
    Job job,
  ) async {
    final response = await dio.post('/jobs/requirements', data: _payload(job));

    final data = Map<String, dynamic>.from(response.data as Map);

    return (
      skills: List<String>.from(data['required_skills'] ?? const []),
      summary: data['skills_summary']?.toString() ?? '',
    );
  }

  Future<String?> fetchStructuredDescription(Job job) async {
    final response = await dio.post('/jobs/description', data: _payload(job));

    return response.data['description']?.toString();
  }

  Future<String> fetchCoverLetter(Job job) async {
    final response = await dio.post('/jobs/cover-letter', data: _payload(job));

    return response.data['cover_letter']?.toString() ?? '';
  }
}
