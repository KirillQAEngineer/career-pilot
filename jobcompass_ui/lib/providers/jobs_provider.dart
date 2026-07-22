import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/feed/services/jobs_api.dart';
import '../models/job.dart';

final jobsApiProvider = Provider<JobsApi>((ref) => JobsApi(ApiClient.dio));

class JobsNotifier extends AsyncNotifier<List<Job>> {
  JobsApi get _api => ref.read(jobsApiProvider);
  String _query = '';
  int _requestSequence = 0;

  @override
  Future<List<Job>> build() {
    return _api.fetchJobs(forceRefresh: false, query: _query);
  }

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery == _query) {
      return;
    }

    _query = normalizedQuery;
    final sequence = ++_requestSequence;
    final previousJobs = state.value;

    try {
      final jobs = await _api.fetchJobs(forceRefresh: false, query: _query);

      if (sequence == _requestSequence) {
        state = AsyncData(jobs);
      }
    } catch (error, stackTrace) {
      if (sequence != _requestSequence) {
        return;
      }

      state = previousJobs == null
          ? AsyncError(error, stackTrace)
          : AsyncData(previousJobs);
    }
  }

  Future<bool> refresh() async {
    final previousJobs = state.value;

    try {
      final jobs = await _api.fetchJobs(forceRefresh: true, query: _query);

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
