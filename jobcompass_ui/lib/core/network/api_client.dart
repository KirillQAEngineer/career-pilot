import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  static Future<void> Function()? _onUnauthorized;
  static bool _isHandlingUnauthorized = false;

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static final Dio dio = _buildClient();

  static Dio _buildClient() {
    final client = Dio(
      BaseOptions(
        baseUrl: _baseUrl,

        // Render's free instances may need extra time to wake from sleep.
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),

        headers: {'Content-Type': 'application/json'},
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final shouldHandleUnauthorized =
              error.response?.statusCode == 401 &&
              error.requestOptions.extra['skipUnauthorizedHandler'] != true &&
              error.requestOptions.headers.containsKey('Authorization');

          if (shouldHandleUnauthorized) {
            _notifyUnauthorized();
          }

          handler.next(error);
        },
      ),
    );

    return client;
  }

  static void setUnauthorizedHandler(Future<void> Function()? handler) {
    _onUnauthorized = handler;
  }

  static Future<void> _notifyUnauthorized() async {
    if (_isHandlingUnauthorized || _onUnauthorized == null) {
      return;
    }

    _isHandlingUnauthorized = true;

    try {
      await _onUnauthorized!();
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  static void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
