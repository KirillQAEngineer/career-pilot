import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jobcompass_ui/app/app.dart';
import 'package:jobcompass_ui/core/network/api_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/auth/me')) {
      return _jsonResponse('''
        {
          "id": "11111111-1111-4111-8111-111111111111",
          "email": "user@example.com",
          "full_name": "User",
          "is_admin": false,
          "analytics_lifetime_access": true,
          "email_verified_at": "2026-07-23T00:00:00Z",
          "created_at": "2026-07-23T00:00:00Z"
        }
        ''', 200);
    }

    if (options.path.endsWith('/profile/me')) {
      return _jsonResponse('''
        {
          "id": 1,
          "profession": "QA Engineer",
          "level": "Middle",
          "skills": "Testing",
          "technologies": "Postman",
          "english_level": "B2",
          "preferred_roles": "QA Engineer",
          "resume_text": ""
        }
        ''', 200);
    }

    return _jsonResponse('{"status":"ok"}', 200);
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

  testWidgets('JobCompass app starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JobCompassApp()));

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('mobile login field receives focus and opens text input', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: JobCompassApp()));
    await tester.pumpAndSettle();

    expect(find.byType(SelectionArea), findsNothing);

    final emailField = find.byType(TextFormField).first;
    await tester.tap(emailField);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(emailField, 'mobile@example.com');
    expect(find.text('mobile@example.com'), findsOneWidget);
  });

  testWidgets('logout clears nested routes and displays sign in', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'valid-token',
      'app_language': 'en',
    });
    ApiClient.dio.httpClientAdapter = _FakeAdapter();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: JobCompassApp()));
    await tester.pumpAndSettle();

    final profileDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.person_outline),
    );
    await tester.tap(profileDestination.first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
