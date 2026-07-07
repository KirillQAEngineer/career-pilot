import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/profile.dart';

final profileProvider = FutureProvider<Profile>((ref) async {
  final response = await ApiClient.dio.get("/profile/me");

  return Profile.fromJson(response.data);
});