import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/app/app.dart';

void main() {
  testWidgets('JobCompass app starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JobCompassApp()));

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
