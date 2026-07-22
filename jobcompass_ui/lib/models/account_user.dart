class AccountUser {
  final String id;
  final String email;
  final String fullName;
  final bool isAdmin;
  final DateTime? createdAt;

  const AccountUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isAdmin,
    required this.createdAt,
  });

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at']?.toString();

    return AccountUser(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: createdAt == null ? null : DateTime.tryParse(createdAt),
    );
  }
}
