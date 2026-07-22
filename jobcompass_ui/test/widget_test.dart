import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jobcompass_ui/app/app.dart';

void main() {
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
}
