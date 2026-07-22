import 'job.dart';

class Application {
  final int id;

  final String jobTitle;
  final String jobCompany;
  final String jobUrl;

  final String? jobLocation;
  final String? jobWorkFormat;
  final String? jobPublishedAt;
  final String? jobDescription;

  final String jobSource;
  final String jobExternalId;

  final String status;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const Application({
    required this.id,
    required this.jobTitle,
    required this.jobCompany,
    required this.jobUrl,
    required this.jobLocation,
    required this.jobWorkFormat,
    required this.jobPublishedAt,
    required this.jobDescription,
    required this.jobSource,
    required this.jobExternalId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  String get stableJobKey {
    if (hasStableIdentity) {
      return '$jobSource::$jobExternalId';
    }

    if (normalizedJobUrl.isNotEmpty) {
      return normalizedJobUrl;
    }

    return identityFingerprint;
  }

  bool get hasStableIdentity =>
      jobSource.isNotEmpty && jobExternalId.isNotEmpty;

  String get normalizedJobUrl {
    final trimmed = jobUrl.trim().toLowerCase();

    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.replaceFirst(RegExp(r'/$'), '');
  }

  String get identityFingerprint {
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    return [
      normalize(jobTitle),
      normalize(jobCompany),
      normalize(jobLocation ?? ''),
    ].join('::');
  }

  Job toJob() {
    return Job(
      externalId: jobExternalId,
      title: jobTitle,
      company: jobCompany,
      location: jobLocation ?? '',
      source: jobSource,
      url: jobUrl,
      description: jobDescription,
      workFormat: jobWorkFormat,
      publishedAt: jobPublishedAt == null
          ? null
          : DateTime.tryParse(jobPublishedAt!),
      score: 0,
      whyMatch: '',
      missingSkills: const <String>[],
      recommendation: '',
    );
  }

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as int,
      jobTitle: json['job_title']?.toString() ?? '',
      jobCompany: json['job_company']?.toString() ?? '',
      jobUrl: json['job_url']?.toString() ?? '',
      jobLocation: json['job_location']?.toString(),
      jobWorkFormat: json['job_work_format']?.toString(),
      jobPublishedAt: json['job_published_at']?.toString(),
      jobDescription: json['job_description']?.toString(),
      jobSource: json['job_source']?.toString() ?? '',
      jobExternalId: json['job_external_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'applied',
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.tryParse(json['archived_at'].toString()),
    );
  }
}
