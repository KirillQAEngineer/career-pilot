import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/application.dart';
import '../models/job.dart';

class ApplicationNotifier extends AsyncNotifier<List<Application>> {
  @override
  Future<List<Application>> build() async {
    return _fetchApplications();
  }

  Future<List<Application>> _fetchApplications() async {
    final response = await ApiClient.dio.get('/applications');

    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) =>
              Application.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  bool isApplied(Job job) {
    return state.maybeWhen(
      data: (applications) {
        return applications.any(
          (application) => application.stableJobKey == job.stableKey,
        );
      },
      orElse: () => false,
    );
  }

  Future<bool> apply(Job job) async {
    if (isApplied(job)) {
      return true;
    }

    try {
      final response = await ApiClient.dio.post(
        '/applications',
        data: {
          'job_title': job.title,
          'job_company': job.company,
          'job_url': job.url,
          'job_location': job.location.isEmpty ? null : job.location,
          'job_work_format': job.workFormat,
          'job_published_at': job.publishedAt?.toUtc().toIso8601String(),
          'job_source': job.source,
          'job_external_id': job.externalId,
        },
      );

      final application = Application.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      final currentApplications = state.value ?? const <Application>[];

      final alreadyExists = currentApplications.any(
        (item) => item.id == application.id,
      );

      if (!alreadyExists) {
        state = AsyncData([application, ...currentApplications]);
      }

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_fetchApplications);
  }
}

final applicationProvider =
    AsyncNotifierProvider<ApplicationNotifier, List<Application>>(
      ApplicationNotifier.new,
    );
