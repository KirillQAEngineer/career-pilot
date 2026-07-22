import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jobcompass_ui/core/network/api_client.dart';
import 'package:jobcompass_ui/providers/auth_provider.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(String body, int statusCode) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Future<AuthState> _waitForAuthState(
  ProviderContainer container,
  bool Function(AuthState state) predicate,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final state = container.read(authProvider);

    if (predicate(state)) {
      return state;
    }

    await Future<void>.delayed(const Duration(milliseconds: 5));
  }

  throw StateError('Timed out waiting for auth state');
}

void main() {
  late HttpClientAdapter originalAdapter;

  setUp(() {
    originalAdapter = ApiClient.dio.httpClientAdapter;
    ApiClient.clearToken();
  });

  tearDown(() {
    ApiClient.dio.httpClientAdapter = originalAdapter;
    ApiClient.clearToken();
    ApiClient.setUnauthorizedHandler(null);
  });

  test(
    'expired stored token returns user to sign in without endless loading',
    () async {
      SharedPreferences.setMockInitialValues({'access_token': 'expired-token'});
      ApiClient.dio.httpClientAdapter = _FakeAdapter(
        (_) => _jsonResponse('{"detail":"Invalid token"}', 401),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authProvider);
      final state = await _waitForAuthState(
        container,
        (state) => !state.isLoading,
      );
      final preferences = await SharedPreferences.getInstance();

      expect(state.isAuthenticated, isFalse);
      expect(state.error, isNull);
      expect(preferences.getString('access_token'), isNull);
      expect(ApiClient.dio.options.headers['Authorization'], isNull);
    },
  );

  test('401 during an active session invalidates it centrally', () async {
    SharedPreferences.setMockInitialValues({'access_token': 'valid-token'});
    ApiClient.dio.httpClientAdapter = _FakeAdapter((options) {
      if (options.path.endsWith('/auth/me')) {
        return _jsonResponse('{}', 200);
      }

      return _jsonResponse('{"detail":"Invalid token"}', 401);
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(authProvider);
    await _waitForAuthState(container, (state) => state.isAuthenticated);

    await expectLater(
      ApiClient.dio.get<void>('/profile/me'),
      throwsA(isA<DioException>()),
    );
    final state = await _waitForAuthState(
      container,
      (state) => !state.isAuthenticated,
    );
    final preferences = await SharedPreferences.getInstance();

    expect(state.isLoading, isFalse);
    expect(state.error, contains('expired'));
    expect(preferences.getString('access_token'), isNull);
  });
}
