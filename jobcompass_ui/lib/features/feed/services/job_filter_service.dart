import 'package:jobcompass_ui/features/feed/models/filterable_job.dart';
import 'package:jobcompass_ui/features/feed/models/job_filters.dart';

class JobFilterService {
  const JobFilterService();

  static const List<String> supportedWorkFormats = <String>[
    'Remote',
    'Hybrid',
    'Office',
  ];

  List<T> apply<T extends FilterableJob>({
    required List<T> jobs,
    required JobFilters filters,
    Set<String> hiddenJobKeys = const <String>{},
    DateTime? now,
  }) {
    final normalizedQuery = filters.query.trim().toLowerCase();
    final referenceTime = now ?? DateTime.now();

    final normalizedWorkFormats = filters.workFormats
        .map((value) => value.trim().toLowerCase())
        .toSet();

    return jobs.where((job) {
      if (hiddenJobKeys.contains(job.stableKey)) {
        return false;
      }

      if (normalizedQuery.isNotEmpty) {
        final matchesSearch =
            job.title.toLowerCase().contains(normalizedQuery) ||
            job.company.toLowerCase().contains(normalizedQuery) ||
            job.location.toLowerCase().contains(normalizedQuery);

        if (!matchesSearch) {
          return false;
        }
      }

      if (normalizedWorkFormats.isNotEmpty) {
        final normalizedJobFormat = _normalizeWorkFormat(job.workFormat);

        if (normalizedJobFormat == null ||
            !normalizedWorkFormats.contains(normalizedJobFormat)) {
          return false;
        }
      }

      if (!_matchesPublicationDate(
        job.publishedAt,
        filters.publicationDate,
        referenceTime,
      )) {
        return false;
      }

      return true;
    }).toList();
  }

  List<String> workFormats<T extends FilterableJob>(List<T> jobs) {
    return supportedWorkFormats;
  }

  String? _normalizeWorkFormat(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim().toLowerCase();

    if (normalized == 'remote') {
      return 'remote';
    }

    if (normalized == 'hybrid') {
      return 'hybrid';
    }

    if (normalized == 'office' ||
        normalized == 'on-site' ||
        normalized == 'onsite' ||
        normalized == 'on site') {
      return 'office';
    }

    return null;
  }

  bool _matchesPublicationDate(
    DateTime? publishedAt,
    PublicationDateFilter filter,
    DateTime now,
  ) {
    if (filter == PublicationDateFilter.anyTime) {
      return true;
    }

    if (publishedAt == null) {
      return false;
    }

    final threshold = switch (filter) {
      PublicationDateFilter.anyTime => now,
      PublicationDateFilter.last24Hours => now.subtract(
        const Duration(hours: 24),
      ),
      PublicationDateFilter.last7Days => now.subtract(const Duration(days: 7)),
      PublicationDateFilter.last30Days => now.subtract(
        const Duration(days: 30),
      ),
    };

    return !publishedAt.isBefore(threshold);
  }
}
