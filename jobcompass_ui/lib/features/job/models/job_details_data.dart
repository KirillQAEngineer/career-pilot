import '../../../models/job.dart';

class JobDetailsData {
  final Job job;
  final int match;
  final String whyMatch;
  final List<String> missingSkills;
  final String recommendation;
  final String coverLetter;
  final String? description;

  const JobDetailsData({
    required this.job,
    required this.match,
    required this.whyMatch,
    required this.missingSkills,
    required this.recommendation,
    required this.coverLetter,
    required this.description,
  });

  factory JobDetailsData.fromJson(Map<String, dynamic> json) {
    return JobDetailsData(
      job: Job.fromJson({
        'job': Map<String, dynamic>.from(json['job'] as Map),
        'score': json['match'] ?? 0,
        'why_match': json['why_match'],
        'missing_skills': json['missing_skills'],
        'recommendation': json['recommendation'],
      }),
      match: json['match'] as int? ?? 0,
      whyMatch: json['why_match']?.toString() ?? '',
      missingSkills: List<String>.from(json['missing_skills'] ?? const []),
      recommendation: json['recommendation']?.toString() ?? '',
      coverLetter: json['cover_letter']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}
