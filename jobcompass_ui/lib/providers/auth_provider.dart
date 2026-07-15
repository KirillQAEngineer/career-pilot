import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
  });

  const AuthState.initial()
    : isAuthenticated = false,
      isLoading = true,
      error = null;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const String _tokenKey = 'access_token';

  @override
  AuthState build() {
    Future.microtask(_restoreSession);

    return const AuthState.initial();
  }

  Future<void> _restoreSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString(_tokenKey);

      if (token == null || token.isEmpty) {
        state = const AuthState(isAuthenticated: false, isLoading: false);

        return;
      }

      ApiClient.setToken(token);

      state = const AuthState(isAuthenticated: true, isLoading: false);
    } catch (_) {
      ApiClient.clearToken();

      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Could not restore session',
      );
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {'username': email.trim(), 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid login response');
      }

      final token = data['access_token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Access token is missing');
      }

      ApiClient.setToken(token);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenKey, token);

      state = const AuthState(isAuthenticated: true, isLoading: false);

      return true;
    } on DioException catch (error) {
      ApiClient.clearToken();

      String message = 'Login failed';

      if (error.response?.statusCode == 401) {
        message = 'Invalid email or password';
      } else if (error.response?.data is Map) {
        final detail = error.response?.data['detail'];

        if (detail != null) {
          message = detail.toString();
        }
      }

      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: message,
      );

      return false;
    } catch (_) {
      ApiClient.clearToken();

      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Login failed',
      );

      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ApiClient.dio.post(
        '/auth/register',
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid registration response');
      }

      final token = data['access_token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Access token is missing');
      }

      ApiClient.setToken(token);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenKey, token);

      state = const AuthState(isAuthenticated: true, isLoading: false);

      return true;
    } on DioException catch (error) {
      ApiClient.clearToken();

      String message = 'Registration failed';

      if (error.response?.statusCode == 409) {
        message = 'User with this email already exists';
      } else if (error.response?.data is Map) {
        final detail = error.response?.data['detail'];

        if (detail != null) {
          message = detail.toString();
        }
      }

      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: message,
      );

      return false;
    } catch (_) {
      ApiClient.clearToken();

      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Registration failed',
      );

      return false;
    }
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_tokenKey);

    ApiClient.clearToken();

    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
