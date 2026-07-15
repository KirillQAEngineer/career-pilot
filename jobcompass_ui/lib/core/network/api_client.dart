import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,

      // Render's free instances may need extra time to wake from sleep.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),

      headers: {"Content-Type": "application/json"},
    ),
  );

  static void setToken(String token) {
    dio.options.headers["Authorization"] = "Bearer $token";
  }

  static void clearToken() {
    dio.options.headers.remove("Authorization");
  }
}
