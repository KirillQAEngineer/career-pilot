import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/applied_job.dart';

final appliedJobsProvider = FutureProvider<List<AppliedJob>>((ref) async {
  final response = await ApiClient.dio.get('/jobs/applied');

  final data = response.data;

  if (data is! List) {
    throw Exception('Invalid applied jobs response: expected a list');
  }

  return data
      .map(
        (item) => AppliedJob.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
});
