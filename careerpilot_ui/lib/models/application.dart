class Application {
  final int id;
  final int userId;

  final String jobTitle;
  final String jobCompany;
  final String jobUrl;

  final String? jobLocation;
  final String? jobWorkFormat;
  final String? jobPublishedAt;

  final String jobSource;
  final String jobExternalId;

  final String status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Application({
    required this.id,
    required this.userId,
    required this.jobTitle,
    required this.jobCompany,
    required this.jobUrl,
    required this.jobLocation,
    required this.jobWorkFormat,
    required this.jobPublishedAt,
    required this.jobSource,
    required this.jobExternalId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  String get stableJobKey {
    if (jobSource.isNotEmpty && jobExternalId.isNotEmpty) {
      return '$jobSource::$jobExternalId';
    }

    return jobUrl;
  }

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      jobTitle: json['job_title']?.toString() ?? '',
      jobCompany: json['job_company']?.toString() ?? '',
      jobUrl: json['job_url']?.toString() ?? '',
      jobLocation: json['job_location']?.toString(),
      jobWorkFormat: json['job_work_format']?.toString(),
      jobPublishedAt: json['job_published_at']?.toString(),
      jobSource: json['job_source']?.toString() ?? '',
      jobExternalId: json['job_external_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'applied',
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }
}
