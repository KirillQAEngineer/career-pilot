import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      // Если запускаешь Android Emulator
      // baseUrl: "http://10.0.2.2:8000",

      // Если запускаешь iPhone Simulator
      // baseUrl: "http://localhost:8000",

      // Если запускаешь на физическом телефоне —
      // укажешь IP своего Mac позже.
      baseUrl: "http://localhost:8000",

      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),

      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  static void setToken(String token) {
    dio.options.headers["Authorization"] = "Bearer $token";
  }

  static void clearToken() {
    dio.options.headers.remove("Authorization");
  }
}