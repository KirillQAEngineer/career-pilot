import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/job.dart';
import 'saved_jobs_provider.dart';

class JobInteractionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _loadSavedJobs();

    return <String>{};
  }

  bool isSaved(Job job) {
    return state.contains(job.url);
  }

  Future<void> _loadSavedJobs() async {
    try {
      final savedJobs = await ref.read(savedJobsProvider.future);

      state = {
        ...state,
        ...savedJobs.where((job) => job.url.isNotEmpty).map((job) => job.url),
      };
    } on DioException {
      // Saved state remains unchanged if the request fails.
    } catch (_) {
      // Saved state remains unchanged if parsing fails.
    }
  }

  Future<bool> saveJob(Job job) async {
    if (isSaved(job)) {
      return true;
    }

    try {
      await ApiClient.dio.post(
        '/jobs/interact',
        data: job.toInteractionJson(action: 'like'),
      );

      state = {...state, job.url};

      ref.invalidate(savedJobsProvider);

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dislikeJob(Job job) async {
    try {
      await ApiClient.dio.post(
        '/jobs/interact',
        data: job.toInteractionJson(action: 'dislike'),
      );

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unsaveJob(String jobUrl) async {
    try {
      await ApiClient.dio.delete(
        '/jobs/saved',
        queryParameters: {'job_url': jobUrl},
      );

      state = {
        for (final url in state)
          if (url != jobUrl) url,
      };

      ref.invalidate(savedJobsProvider);

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final jobInteractionProvider =
    NotifierProvider<JobInteractionNotifier, Set<String>>(
      JobInteractionNotifier.new,
    );
