import 'package:jobcompass_ui/features/feed/models/filterable_job.dart';

class Job implements FilterableJob {
  final String externalId;
  @override
  final String title;
  @override
  final String company;
  @override
  final String location;
  final String source;
  final String url;
  final String? description;
  @override
  final String? workFormat;
  @override
  final DateTime? publishedAt;

  final double score;

  final String whyMatch;
  final List<String> missingSkills;
  final String recommendation;

  Job({
    required this.externalId,
    required this.title,
    required this.company,
    required this.location,
    required this.source,
    required this.url,
    this.description,
    this.workFormat,
    this.publishedAt,
    required this.score,
    required this.whyMatch,
    required this.missingSkills,
    required this.recommendation,
  });

  @override
  String get stableKey {
    if (hasStableIdentity) {
      return '$source::$externalId';
    }

    if (normalizedUrl.isNotEmpty) {
      return normalizedUrl;
    }

    return identityFingerprint;
  }

  bool get hasStableIdentity => source.isNotEmpty && externalId.isNotEmpty;

  String get normalizedUrl {
    final trimmed = url.trim().toLowerCase();

    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.replaceFirst(RegExp(r'/$'), '');
  }

  String get identityFingerprint {
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    return [
      normalize(title),
      normalize(company),
      normalize(location),
    ].join('::');
  }

  Map<String, dynamic> toInteractionJson({required String action}) {
    return {
      'job_title': title,
      'job_company': company,
      'job_url': url,
      'job_location': location.isEmpty ? null : location,
      'job_work_format': workFormat,
      'job_published_at': publishedAt?.toUtc().toIso8601String(),
      'job_description': description,
      'job_source': source,
      'job_external_id': externalId,
      'action': action,
    };
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>;

    return Job(
      externalId: job['external_id']?.toString() ?? '',
      title: job['title'] ?? '',
      company: job['company'] ?? '',
      location: job['location'] ?? '',
      source: job['source'] ?? '',
      url: job['url'] ?? '',
      description: job['description']?.toString(),
      workFormat: job['work_format']?.toString(),
      publishedAt: job['published_at'] == null
          ? null
          : DateTime.tryParse(job['published_at'].toString()),
      score: (json['score'] ?? 0).toDouble(),
      whyMatch: json['why_match'] ?? '',
      missingSkills: List<String>.from(json['missing_skills'] ?? const []),
      recommendation: json['recommendation'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Job &&
        other.externalId == externalId &&
        other.title == title &&
        other.company == company &&
        other.location == location &&
        other.source == source &&
        other.url == url &&
        other.description == description &&
        other.workFormat == workFormat &&
        other.publishedAt == publishedAt;
  }

  @override
  int get hashCode => Object.hash(
    externalId,
    title,
    company,
    location,
    source,
    url,
    description,
    workFormat,
    publishedAt,
  );
}
