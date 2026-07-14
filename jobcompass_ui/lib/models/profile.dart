class Profile {
  final int id;
  final String profession;
  final String level;
  final String skills;
  final String technologies;
  final String englishLevel;
  final String preferredRoles;
  final String resumeText;

  const Profile({
    required this.id,
    required this.profession,
    required this.level,
    required this.skills,
    required this.technologies,
    required this.englishLevel,
    required this.preferredRoles,
    required this.resumeText,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int? ?? 0,
      profession: json['profession'] as String? ?? '',
      level: json['level'] as String? ?? '',
      skills: json['skills'] as String? ?? '',
      technologies: json['technologies'] as String? ?? '',
      englishLevel: json['english_level'] as String? ?? '',
      preferredRoles: json['preferred_roles'] as String? ?? '',
      resumeText: json['resume_text'] as String? ?? '',
    );
  }
}
