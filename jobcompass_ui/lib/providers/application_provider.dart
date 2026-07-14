import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jobcompass_ui/core/network/api_client.dart';
import 'package:jobcompass_ui/features/applications/services/application_api.dart';
import 'package:jobcompass_ui/models/application.dart';
import 'package:jobcompass_ui/models/application_stats.dart';
import 'package:jobcompass_ui/models/job.dart';
import 'package:jobcompass_ui/models/saved_job.dart';

final applicationApiProvider = Provider<ApplicationApi>(
  (ref) => ApplicationApi(ApiClient.dio),
);

class ApplicationStatsNotifier extends AsyncNotifier<ApplicationStats> {
  ApplicationApi get _api => ref.read(applicationApiProvider);

  @override
  Future<ApplicationStats> build() {
    return _api.fetchStats();
  }

  Future<bool> updateAnalyticsTotals(Map<String, int?> totals) async {
    try {
      final updatedStats = await _api.updateAnalyticsTotals(totals);

      state = AsyncData(updatedStats);

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final applicationStatsProvider =
    AsyncNotifierProvider<ApplicationStatsNotifier, ApplicationStats>(
      ApplicationStatsNotifier.new,
    );

class ApplicationNotifier extends AsyncNotifier<List<Application>> {
  ApplicationApi get _api => ref.read(applicationApiProvider);

  @override
  Future<List<Application>> build() async {
    return _api.fetchApplications();
  }

  bool isApplied(Job job) {
    return state.maybeWhen(
      data: (applications) {
        return applications.any((application) {
          if (application.hasStableIdentity && job.hasStableIdentity) {
            return application.stableJobKey == job.stableKey;
          }

          if (application.normalizedJobUrl.isNotEmpty &&
              application.normalizedJobUrl == job.normalizedUrl) {
            return true;
          }

          return application.identityFingerprint == job.identityFingerprint &&
              (!application.hasStableIdentity || !job.hasStableIdentity);
        });
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
      await _api.recordApplyInteraction(job);

      final currentApplications = state.value ?? const <Application>[];

      final updatedApplications = [
        application,
        for (final item in currentApplications)
          if (item.id != application.id) item,
      ];

      state = AsyncData(updatedApplications);

      ref.invalidate(applicationStatsProvider);
      ref.invalidate(archivedApplicationsProvider);

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
      ref.invalidate(archivedApplicationsProvider);

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
    ref.invalidate(archivedApplicationsProvider);
  }

  Future<bool> archive(int applicationId) async {
    try {
      final archivedApplication = await _api.archiveApplication(applicationId);
      final currentApplications = state.value ?? const <Application>[];

      state = AsyncData(
        currentApplications
            .where((application) => application.id != archivedApplication.id)
            .toList(),
      );

      ref.invalidate(applicationStatsProvider);
      ref.invalidate(archivedApplicationsProvider);

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unarchive(int applicationId) async {
    try {
      final application = await _api.unarchiveApplication(applicationId);
      final currentApplications = state.value ?? const <Application>[];
      final updatedApplications = [
        application,
        for (final item in currentApplications)
          if (item.id != application.id) item,
      ];

      updatedApplications.sort(
        (left, right) => right.updatedAt.compareTo(left.updatedAt),
      );

      state = AsyncData(updatedApplications);

      ref.invalidate(applicationStatsProvider);
      ref.invalidate(archivedApplicationsProvider);

      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final applicationProvider =
    AsyncNotifierProvider<ApplicationNotifier, List<Application>>(
      ApplicationNotifier.new,
    );

class ArchivedApplicationsNotifier extends AsyncNotifier<List<Application>> {
  ApplicationApi get _api => ref.read(applicationApiProvider);

  @override
  Future<List<Application>> build() {
    return _api.fetchArchivedApplications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_api.fetchArchivedApplications);
  }
}

final archivedApplicationsProvider =
    AsyncNotifierProvider<ArchivedApplicationsNotifier, List<Application>>(
      ArchivedApplicationsNotifier.new,
    );
