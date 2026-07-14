class ApplicationStats {
  final int totalApplications;
  final int activeProcesses;
  final int interviews;
  final int offers;
  final int rejected;

  const ApplicationStats({
    required this.totalApplications,
    required this.activeProcesses,
    required this.interviews,
    required this.offers,
    required this.rejected,
  });

  factory ApplicationStats.fromJson(Map<String, dynamic> json) {
    return ApplicationStats(
      totalApplications: json['total_applications'] as int,
      activeProcesses: json['active_processes'] as int,
      interviews: json['interviews'] as int,
      offers: json['offers'] as int,
      rejected: json['rejected'] as int,
    );
  }
}
