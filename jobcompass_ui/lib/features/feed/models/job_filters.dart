enum PublicationDateFilter { anyTime, last24Hours, last7Days, last30Days }

class JobFilters {
  final String query;
  final Set<String> workFormats;
  final PublicationDateFilter publicationDate;

  const JobFilters({
    this.query = '',
    this.workFormats = const <String>{},
    this.publicationDate = PublicationDateFilter.anyTime,
  });

  bool get hasStructuredFilters {
    return workFormats.isNotEmpty ||
        publicationDate != PublicationDateFilter.anyTime;
  }

  int get activeFilterCount {
    var count = 0;

    if (workFormats.isNotEmpty) {
      count++;
    }

    if (publicationDate != PublicationDateFilter.anyTime) {
      count++;
    }

    return count;
  }

  JobFilters copyWith({
    String? query,
    Set<String>? workFormats,
    PublicationDateFilter? publicationDate,
  }) {
    return JobFilters(
      query: query ?? this.query,
      workFormats: workFormats ?? this.workFormats,
      publicationDate: publicationDate ?? this.publicationDate,
    );
  }

  JobFilters clearStructuredFilters() {
    return JobFilters(query: query);
  }
}
