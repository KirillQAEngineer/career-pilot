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

  factory Profile.empty() {
    return const Profile(
      id: 0,
      profession: '',
      level: '',
      skills: '',
      technologies: '',
      englishLevel: '',
      preferredRoles: '',
      resumeText: '',
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int? ?? 0,
      profession: json['profession'] as String? ?? '',
      level: json['level'] as String? ?? '',
      skills: _formatCommaSeparated(json['skills'] as String? ?? ''),
      technologies: _formatCommaSeparated(
        json['technologies'] as String? ?? '',
      ),
      englishLevel: json['english_level'] as String? ?? '',
      preferredRoles: _formatCommaSeparated(
        json['preferred_roles'] as String? ?? '',
      ),
      resumeText: json['resume_text'] as String? ?? '',
    );
  }

  static String _formatCommaSeparated(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
  }
}
