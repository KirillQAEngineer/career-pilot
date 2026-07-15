import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/feed/services/jobs_api.dart';
import '../models/job.dart';

final jobsApiProvider = Provider<JobsApi>((ref) => JobsApi(ApiClient.dio));

class JobsNotifier extends AsyncNotifier<List<Job>> {
  JobsApi get _api => ref.read(jobsApiProvider);

  @override
  Future<List<Job>> build() {
    return _api.fetchJobs(forceRefresh: false);
  }

  Future<bool> refresh() async {
    final previousJobs = state.value;

    try {
      final jobs = await _api.fetchJobs(forceRefresh: true);

      state = AsyncData(jobs);

      return true;
    } catch (error, stackTrace) {
      if (previousJobs != null) {
        state = AsyncData(previousJobs);
      } else {
        state = AsyncError(error, stackTrace);
      }

      return false;
    }
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, List<Job>>(
  JobsNotifier.new,
);
