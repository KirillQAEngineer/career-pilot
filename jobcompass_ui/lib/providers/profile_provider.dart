import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/profile.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  try {
    final response = await ApiClient.dio.get('/profile/me');

    return Profile.fromJson(response.data);
  } on DioException catch (error) {
    if (error.response?.statusCode == 404) {
      return null;
    }

    rethrow;
  }
});

final profileUpdateProvider =
    AsyncNotifierProvider<ProfileUpdateNotifier, void>(
      ProfileUpdateNotifier.new,
    );

class ProfileUpdateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> updateProfile({
    required String profession,
    required String level,
    required List<String> skills,
    required List<String> technologies,
    required String englishLevel,
    required List<String> preferredRoles,
  }) async {
    if (state.isLoading) {
      return false;
    }

    state = const AsyncLoading();

    try {
      await ApiClient.dio.put(
        '/profile/me',
        data: {
          'profession': profession,
          'level': level,
          'skills': skills,
          'technologies': technologies,
          'english_level': englishLevel,
          'preferred_roles': preferredRoles,
        },
      );

      ref.invalidate(profileProvider);

      state = const AsyncData(null);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }
}

final profileDeleteProvider =
    AsyncNotifierProvider<ProfileDeleteNotifier, void>(
      ProfileDeleteNotifier.new,
    );

class ProfileDeleteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> deleteProfile() async {
    if (state.isLoading) {
      return false;
    }

    state = const AsyncLoading();

    try {
      await ApiClient.dio.delete('/profile/me');

      ref.invalidate(profileProvider);

      state = const AsyncData(null);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }
}
