import 'package:jobcompass_ui/features/feed/models/filterable_job.dart';
import 'package:jobcompass_ui/models/job.dart';

class SavedJob implements FilterableJob {
  final int id;
  @override
  final String title;
  @override
  final String company;
  final String url;
  final String source;
  final String externalId;
  @override
  final String location;
  @override
  final String? workFormat;
  @override
  final DateTime? publishedAt;
  final String? description;
  final String action;
  final DateTime? createdAt;

  const SavedJob({
    required this.id,
    required this.title,
    required this.company,
    required this.url,
    this.source = '',
    this.externalId = '',
    required this.location,
    required this.workFormat,
    required this.publishedAt,
    this.description,
    required this.action,
    required this.createdAt,
  });

  @override
  String get stableKey {
    if (source.isNotEmpty && externalId.isNotEmpty) {
      return '$source::$externalId';
    }

    return url;
  }

  Job toJob() {
    return Job(
      externalId: externalId,
      title: title,
      company: company,
      location: location,
      source: source,
      url: url,
      description: description,
      workFormat: workFormat,
      publishedAt: publishedAt,
      score: 0,
      whyMatch: '',
      missingSkills: const <String>[],
      recommendation: '',
    );
  }

  factory SavedJob.fromJson(Map<String, dynamic> json) {
    return SavedJob(
      id: json['id'] as int? ?? 0,
      title: json['job_title'] as String? ?? '',
      company: json['job_company'] as String? ?? '',
      url: json['job_url'] as String? ?? '',
      source: json['job_source']?.toString() ?? '',
      externalId: json['job_external_id']?.toString() ?? '',
      location: json['job_location']?.toString() ?? '',
      workFormat: json['job_work_format']?.toString(),
      publishedAt: json['job_published_at'] == null
          ? null
          : DateTime.tryParse(json['job_published_at'].toString()),
      description: json['job_description']?.toString(),
      action: json['action'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
