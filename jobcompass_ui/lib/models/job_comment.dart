class JobComment {
  final String jobSource;
  final String jobExternalId;
  final String comment;
  final DateTime? updatedAt;

  const JobComment({
    required this.jobSource,
    required this.jobExternalId,
    required this.comment,
    required this.updatedAt,
  });

  String get stableKey => buildStableKey(jobSource, jobExternalId);

  static String buildStableKey(String jobSource, String jobExternalId) {
    return '${jobSource.trim().toLowerCase()}::${jobExternalId.trim()}';
  }

  factory JobComment.fromJson(Map<String, dynamic> json) {
    return JobComment(
      jobSource: json['job_source']?.toString() ?? '',
      jobExternalId: json['job_external_id']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }
}
