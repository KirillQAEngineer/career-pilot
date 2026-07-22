import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import 'account_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? notice;
  final String? verificationEmail;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
    this.notice,
    this.verificationEmail,
  });

  const AuthState.initial()
    : isAuthenticated = false,
      isLoading = true,
      error = null,
      notice = null,
      verificationEmail = null;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? notice,
    String? verificationEmail,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      notice: clearNotice ? null : notice ?? this.notice,
      verificationEmail: clearNotice
          ? null
          : verificationEmail ?? this.verificationEmail,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const String _tokenKey = 'access_token';

  @override
  AuthState build() {
    ApiClient.setUnauthorizedHandler(_handleUnauthorized);
    ref.onDispose(() => ApiClient.setUnauthorizedHandler(null));
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

      await ApiClient.dio.get(
        '/auth/me',
        options: Options(extra: const {'skipUnauthorizedHandler': true}),
      );

      ref.invalidate(currentUserProvider);
      state = const AuthState(isAuthenticated: true, isLoading: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _clearSession();

        return;
      }

      ApiClient.clearToken();

      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Could not connect to the service. Please try again.',
      );
    } catch (_) {
      await _clearSession(error: 'Could not restore session');
    }
  }

  Future<void> _handleUnauthorized() async {
    await _clearSession(error: 'Your session has expired. Please sign in.');
  }

  Future<void> _clearSession({String? error}) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_tokenKey);
    ApiClient.clearToken();
    ref.invalidate(currentUserProvider);

    state = AuthState(isAuthenticated: false, isLoading: false, error: error);
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearNotice: true,
    );

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
      ref.invalidate(currentUserProvider);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_tokenKey, token);

      state = const AuthState(isAuthenticated: true, isLoading: false);

      return true;
    } on DioException catch (error) {
      ApiClient.clearToken();

      String message = 'Login failed';

      if (error.response?.statusCode == 401) {
        message = 'Invalid email or password';
      } else if (error.response?.statusCode == 403) {
        message = 'email_verification_required';
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
        verificationEmail: error.response?.statusCode == 403
            ? email.trim().toLowerCase()
            : null,
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
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearNotice: true,
    );

    try {
      final response = await ApiClient.dio.post(
        '/auth/register',
        data: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.data is! Map) {
        throw Exception('Invalid registration response');
      }

      final normalizedEmail = email.trim().toLowerCase();
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        notice: 'registration_check_email',
        verificationEmail: normalizedEmail,
      );

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

  Future<bool> resendVerification(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      state = state.copyWith(error: 'enter_email', clearNotice: true);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await ApiClient.dio.post(
        '/auth/resend-verification',
        data: {'email': normalizedEmail},
      );
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        notice: 'verification_sent',
        verificationEmail: normalizedEmail,
      );
      return true;
    } on DioException catch (error) {
      final detail = error.response?.data is Map
          ? error.response?.data['detail']?.toString()
          : null;
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: detail ?? 'failed_send_verification',
        verificationEmail: normalizedEmail,
      );
      return false;
    }
  }

  Future<bool> sendCurrentUserVerification() async {
    try {
      await ApiClient.dio.post('/auth/me/send-verification');
      ref.invalidate(currentUserProvider);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSession();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearNotice: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
