class Job {
  final String externalId;
  final String title;
  final String company;
  final String location;
  final String source;
  final String url;

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
    required this.score,
    required this.whyMatch,
    required this.missingSkills,
    required this.recommendation,
  });

  String get stableKey {
    if (source.isNotEmpty && externalId.isNotEmpty) {
      return '$source::$externalId';
    }

    return url;
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
      score: (json['score'] ?? 0).toDouble(),
      whyMatch: json['why_match'] ?? '',
      missingSkills: List<String>.from(json['missing_skills'] ?? const []),
      recommendation: json['recommendation'] ?? '',
    );
  }
}
