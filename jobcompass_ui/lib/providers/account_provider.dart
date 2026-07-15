import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/account_user.dart';

final currentUserProvider = FutureProvider<AccountUser>((ref) async {
  final response = await ApiClient.dio.get('/auth/me');

  return AccountUser.fromJson(Map<String, dynamic>.from(response.data as Map));
});
