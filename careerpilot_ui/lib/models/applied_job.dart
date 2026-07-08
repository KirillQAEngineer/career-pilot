class AppliedJob {
  final int id;
  final int userId;
  final String title;
  final String company;
  final String url;
  final String action;
  final DateTime? createdAt;

  const AppliedJob({
    required this.id,
    required this.userId,
    required this.title,
    required this.company,
    required this.url,
    required this.action,
    required this.createdAt,
  });

  factory AppliedJob.fromJson(Map<String, dynamic> json) {
    return AppliedJob(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['job_title'] as String? ?? '',
      company: json['job_company'] as String? ?? '',
      url: json['job_url'] as String? ?? '',
      action: json['action'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
