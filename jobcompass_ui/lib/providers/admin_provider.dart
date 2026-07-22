import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/admin/services/admin_api.dart';
import '../models/account_user.dart';
import 'account_provider.dart';

final adminApiProvider = Provider<AdminApi>((ref) => AdminApi(ApiClient.dio));

class AdminDashboardNotifier extends AsyncNotifier<AdminDashboardData> {
  AdminApi get _api => ref.read(adminApiProvider);

  @override
  Future<AdminDashboardData> build() async {
    final results = await Future.wait([_api.fetchStats(), _api.fetchUsers()]);

    return AdminDashboardData(
      stats: results[0] as AdminStats,
      users: results[1] as List<AccountUser>,
    );
  }

  Future<bool> updateRole({
    required String userId,
    required bool isAdmin,
  }) async {
    try {
      await _api.updateAdminRole(userId: userId, isAdmin: isAdmin);
      ref.invalidate(adminUserProvider(userId));
      ref.invalidate(currentUserProvider);
      final results = await Future.wait([_api.fetchStats(), _api.fetchUsers()]);

      state = AsyncData(
        AdminDashboardData(
          stats: results[0] as AdminStats,
          users: results[1] as List<AccountUser>,
        ),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAnalyticsAccess({
    required String userId,
    required bool hasAccess,
  }) async {
    try {
      await _api.updateAnalyticsAccess(userId: userId, hasAccess: hasAccess);
      ref.invalidate(adminUserProvider(userId));
      ref.invalidate(currentUserProvider);
      final results = await Future.wait([_api.fetchStats(), _api.fetchUsers()]);

      state = AsyncData(
        AdminDashboardData(
          stats: results[0] as AdminStats,
          users: results[1] as List<AccountUser>,
        ),
      );

      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardData>(
      AdminDashboardNotifier.new,
    );

final adminUserProvider = FutureProvider.family<AdminUserDetail, String>((
  ref,
  userId,
) async {
  return ref.read(adminApiProvider).fetchUser(userId);
});
