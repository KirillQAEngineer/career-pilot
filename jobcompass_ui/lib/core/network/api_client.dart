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

      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),

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
