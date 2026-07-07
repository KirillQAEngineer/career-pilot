class SavedJob {
  final int id;
  final int userId;
  final String title;
  final String company;
  final String url;
  final String action;
  final DateTime? createdAt;

  const SavedJob({
    required this.id,
    required this.userId,
    required this.title,
    required this.company,
    required this.url,
    required this.action,
    required this.createdAt,
  });

  factory SavedJob.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at']?.toString();

    return SavedJob(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      title: json['job_title'] as String? ?? '',
      company: json['job_company'] as String? ?? '',
      url: json['job_url'] as String? ?? '',
      action: json['action'] as String? ?? '',
      createdAt: createdAtValue == null
          ? null
          : DateTime.tryParse(createdAtValue),
    );
  }
}