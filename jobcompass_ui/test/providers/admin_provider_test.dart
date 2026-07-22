import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/features/admin/services/admin_api.dart';
import 'package:jobcompass_ui/models/account_user.dart';
import 'package:jobcompass_ui/providers/admin_provider.dart';

class FakeAdminApi extends AdminApi {
  FakeAdminApi()
    : users = [
        AccountUser(
          id: '11111111-1111-4111-8111-111111111111',
          email: 'admin@example.com',
          fullName: 'Admin',
          isAdmin: true,
          createdAt: DateTime.utc(2026, 7, 15),
        ),
        AccountUser(
          id: '22222222-2222-4222-8222-222222222222',
          email: 'user@example.com',
          fullName: 'User',
          isAdmin: false,
          createdAt: DateTime.utc(2026, 7, 15),
        ),
      ],
      super(Dio());

  List<AccountUser> users;

  @override
  Future<AdminStats> fetchStats() async {
    return AdminStats(
      totalUsers: users.length,
      totalAdmins: users.where((user) => user.isAdmin).length,
    );
  }

  @override
  Future<List<AccountUser>> fetchUsers() async => users;

  @override
  Future<AccountUser> updateAdminRole({
    required String userId,
    required bool isAdmin,
  }) async {
    final current = users.firstWhere((user) => user.id == userId);
    final updated = AccountUser(
      id: current.id,
      email: current.email,
      fullName: current.fullName,
      isAdmin: isAdmin,
      createdAt: current.createdAt,
    );

    users = [
      for (final user in users)
        if (user.id == userId) updated else user,
    ];

    return updated;
  }

  @override
  Future<AccountUser> updateAnalyticsAccess({
    required String userId,
    required bool hasAccess,
  }) async {
    final current = users.firstWhere((user) => user.id == userId);
    final updated = AccountUser(
      id: current.id,
      email: current.email,
      fullName: current.fullName,
      isAdmin: current.isAdmin,
      analyticsLifetimeAccess: hasAccess,
      createdAt: current.createdAt,
    );

    users = [
      for (final user in users)
        if (user.id == userId) updated else user,
    ];

    return updated;
  }
}

void main() {
  test('admin dashboard loads totals and updates user role', () async {
    final api = FakeAdminApi();
    final container = ProviderContainer(
      overrides: [adminApiProvider.overrideWithValue(api)],
    );

    addTearDown(container.dispose);

    final initial = await container.read(adminDashboardProvider.future);

    expect(initial.stats.totalUsers, 2);
    expect(initial.stats.totalAdmins, 1);

    final success = await container
        .read(adminDashboardProvider.notifier)
        .updateRole(
          userId: '22222222-2222-4222-8222-222222222222',
          isAdmin: true,
        );
    final updated = container.read(adminDashboardProvider).requireValue;

    expect(success, isTrue);
    expect(updated.stats.totalAdmins, 2);
    expect(
      updated.users
          .firstWhere(
            (user) => user.id == '22222222-2222-4222-8222-222222222222',
          )
          .isAdmin,
      isTrue,
    );

    final accessUpdated = await container
        .read(adminDashboardProvider.notifier)
        .updateAnalyticsAccess(
          userId: '22222222-2222-4222-8222-222222222222',
          hasAccess: true,
        );
    final userWithAccess = container
        .read(adminDashboardProvider)
        .requireValue
        .users
        .firstWhere(
          (user) => user.id == '22222222-2222-4222-8222-222222222222',
        );

    expect(accessUpdated, isTrue);
    expect(userWithAccess.analyticsLifetimeAccess, isTrue);
  });
}
