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
    final result = List<Application>.of(applications);

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
}
