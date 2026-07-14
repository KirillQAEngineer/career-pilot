class ApplicationStats {
  final int totalApplications;
  final int totalScreenings;
  final int totalInterviews;
  final int totalOffers;
  final int totalRejected;

  final int activeProcesses;
  final int screeningInProgress;
  final int interviewInProgress;
  final int technicalInterviewInProgress;
  final int offerInProgress;

  const ApplicationStats({
    required this.totalApplications,
    required this.totalScreenings,
    required this.totalInterviews,
    required this.totalOffers,
    required this.totalRejected,
    required this.activeProcesses,
    required this.screeningInProgress,
    required this.interviewInProgress,
    required this.technicalInterviewInProgress,
    required this.offerInProgress,
  });

  factory ApplicationStats.fromJson(Map<String, dynamic> json) {
    return ApplicationStats(
      totalApplications: json['total_applications'] as int,
      totalScreenings: json['total_screenings'] as int,
      totalInterviews: json['total_interviews'] as int,
      totalOffers: json['total_offers'] as int,
      totalRejected: json['total_rejected'] as int,
      activeProcesses: json['active_processes'] as int,
      screeningInProgress: json['screening_in_progress'] as int,
      interviewInProgress: json['interview_in_progress'] as int,
      technicalInterviewInProgress:
          json['technical_interview_in_progress'] as int,
      offerInProgress: json['offer_in_progress'] as int,
    );
  }
}
