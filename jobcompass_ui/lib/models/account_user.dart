class AccountUser {
  final String id;
  final String email;
  final String fullName;
  final bool isAdmin;
  final bool emailVerified;
  final bool emailVerificationRequired;
  final bool analyticsLifetimeAccess;
  final DateTime? createdAt;

  const AccountUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isAdmin,
    this.emailVerified = false,
    this.emailVerificationRequired = false,
    this.analyticsLifetimeAccess = false,
    required this.createdAt,
  });

  bool get hasAnalyticsAccess => isAdmin || analyticsLifetimeAccess;

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at']?.toString();

    return AccountUser(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      isAdmin: json['is_admin'] as bool? ?? false,
      emailVerified: json['email_verified_at'] != null,
      emailVerificationRequired:
          json['email_verification_required'] as bool? ?? false,
      analyticsLifetimeAccess:
          json['analytics_lifetime_access'] as bool? ?? false,
      createdAt: createdAt == null ? null : DateTime.tryParse(createdAt),
    );
  }
}
