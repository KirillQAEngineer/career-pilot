import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/job.dart';

class JobsNotifier extends AsyncNotifier<List<Job>> {
  @override
  Future<List<Job>> build() {
    return _fetch(forceRefresh: false);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(forceRefresh: true));
  }

  Future<List<Job>> _fetch({required bool forceRefresh}) async {
    final response = await ApiClient.dio.get(
      '/jobs/feed',
      queryParameters: {'limit': 150, if (forceRefresh) 'refresh': true},
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid jobs response: expected a list');
    }

    return data
        .map((item) => Job.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<Job>>(
  JobsNotifier.new,
);
