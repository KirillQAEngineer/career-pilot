import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/job.dart';

final jobsProvider = FutureProvider<List<Job>>((ref) async {
  final response = await ApiClient.dio.get(
    '/jobs/feed',
    queryParameters: {'limit': 120},
  );

  final data = response.data;

  if (data is! List) {
    throw Exception('Invalid jobs response: expected a list');
  }

  return data
      .map((item) => Job.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});
