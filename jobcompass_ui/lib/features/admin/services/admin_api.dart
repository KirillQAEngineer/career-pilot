import 'package:dio/dio.dart';

import '../../../models/account_user.dart';
import '../../../models/profile.dart';

class AdminStats {
  final int totalUsers;
  final int totalAdmins;

  const AdminStats({required this.totalUsers, required this.totalAdmins});

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] as int? ?? 0,
      totalAdmins: json['total_admins'] as int? ?? 0,
    );
  }
}

class AdminUserDetail {
  final AccountUser user;
  final Profile? profile;

  const AdminUserDetail({required this.user, required this.profile});

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];

    return AdminUserDetail(
      user: AccountUser.fromJson(json),
      profile: profileJson is Map
          ? Profile.fromJson(Map<String, dynamic>.from(profileJson))
          : null,
    );
  }
}

class AdminDashboardData {
  final AdminStats stats;
  final List<AccountUser> users;

  const AdminDashboardData({required this.stats, required this.users});
}

class AdminApi {
  const AdminApi(this.dio);

  final Dio dio;

  Future<AdminStats> fetchStats() async {
    final response = await dio.get('/admin/stats');

    return AdminStats.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<AccountUser>> fetchUsers() async {
    final response = await dio.get('/admin/users');
    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) =>
              AccountUser.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AdminUserDetail> fetchUser(String userId) async {
    final response = await dio.get('/admin/users/$userId');

    return AdminUserDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AccountUser> updateAdminRole({
    required String userId,
    required bool isAdmin,
  }) async {
    final response = await dio.patch(
      '/admin/users/$userId/role',
      data: {'is_admin': isAdmin},
    );

    return AccountUser.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
