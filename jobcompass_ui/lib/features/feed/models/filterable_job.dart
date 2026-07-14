abstract interface class FilterableJob {
  String get title;
  String get company;
  String get location;
  String? get workFormat;
  DateTime? get publishedAt;
  String get stableKey;
}
