import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:careerpilot_ui/core/network/api_client.dart';
import 'package:careerpilot_ui/features/applications/services/application_api.dart';
import 'package:careerpilot_ui/models/application.dart';
import 'package:careerpilot_ui/models/application_stats.dart';
import 'package:careerpilot_ui/models/job.dart';
import 'package:careerpilot_ui/models/saved_job.dart';

final applicationApiProvider = Provider<ApplicationApi>(
  (ref) => ApplicationApi(ApiClient.dio),
);

final applicationStatsProvider = FutureProvider<ApplicationStats>((ref) {
  final api = ref.watch(applicationApiProvider);

  return api.fetchStats();
});

class ApplicationNotifier extends AsyncNotifier<List<Application>> {
  ApplicationApi get _api => ref.read(applicationApiProvider);

  @override
  Future<List<Application>> build() async {
    return _api.fetchApplications();
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

  Future<bool> applySavedJob(SavedJob savedJob) {
    return apply(savedJob.toJob());
  }

  Future<bool> apply(Job job) async {
    if (isApplied(job)) {
      return true;
    }

    try {
      final application = await _api.createApplication(job);

      final currentApplications = state.value ?? const <Application>[];

      final alreadyExists = currentApplications.any(
        (item) => item.id == application.id,
      );

      if (!alreadyExists) {
        state = AsyncData([application, ...currentApplications]);
      }

      ref.invalidate(applicationStatsProvider);

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus({
    required int applicationId,
    required String status,
  }) async {
    try {
      final updatedApplication = await _api.updateStatus(
        applicationId: applicationId,
        status: status,
      );

      final currentApplications = state.value;

      if (currentApplications == null) {
        return false;
      }

      final updatedApplications = currentApplications.map((application) {
        if (application.id == updatedApplication.id) {
          return updatedApplication;
        }

        return application;
      }).toList();

      updatedApplications.sort(
        (left, right) => right.updatedAt.compareTo(left.updatedAt),
      );

      state = AsyncData(updatedApplications);

      ref.invalidate(applicationStatsProvider);

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_api.fetchApplications);

    ref.invalidate(applicationStatsProvider);
  }
}

final applicationProvider =
    AsyncNotifierProvider<ApplicationNotifier, List<Application>>(
      ApplicationNotifier.new,
    );
