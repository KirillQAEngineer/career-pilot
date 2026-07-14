import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/saved_job.dart';

final savedJobsProvider = FutureProvider<List<SavedJob>>((ref) async {
  final response = await ApiClient.dio.get('/jobs/saved');

  final data = response.data;

  if (data is! List) {
    throw Exception('Invalid saved jobs response: expected a list');
  }

  return data
      .map((item) => SavedJob.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});
