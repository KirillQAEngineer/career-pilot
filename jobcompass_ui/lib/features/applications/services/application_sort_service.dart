import '../../../models/application.dart';

class ApplicationSortService {
  const ApplicationSortService();

  static const Map<String, int> _statusPriority = <String, int>{
    'rejected': 0,
    'applied': 1,
    'screening': 2,
    'interview': 3,
    'technical_interview': 4,
    'offer': 5,
  };

  List<Application> sort(List<Application> applications) {
    final result = <Application>[];

    for (final application in applications) {
      final existingIndex = result.indexWhere(
        (existing) => _isSameVacancy(existing, application),
      );

      if (existingIndex == -1) {
        result.add(application);
        continue;
      }

      final existing = result[existingIndex];

      if (application.updatedAt.isAfter(existing.updatedAt) ||
          (application.updatedAt == existing.updatedAt &&
              application.id > existing.id)) {
        result[existingIndex] = application;
      }
    }

    result.sort((left, right) {
      final leftPriority = _statusPriority[left.status] ?? -1;
      final rightPriority = _statusPriority[right.status] ?? -1;

      final statusComparison = rightPriority.compareTo(leftPriority);

      if (statusComparison != 0) {
        return statusComparison;
      }

      final updatedComparison = right.updatedAt.compareTo(left.updatedAt);

      if (updatedComparison != 0) {
        return updatedComparison;
      }

      return right.id.compareTo(left.id);
    });

    return result;
  }

  bool _isSameVacancy(Application left, Application right) {
    if (left.hasStableIdentity &&
        right.hasStableIdentity &&
        left.stableJobKey == right.stableJobKey) {
      return true;
    }

    if (left.normalizedJobUrl.isNotEmpty &&
        left.normalizedJobUrl == right.normalizedJobUrl) {
      return true;
    }

    if (left.identityFingerprint != right.identityFingerprint) {
      return false;
    }

    return !left.hasStableIdentity || !right.hasStableIdentity;
  }
}
