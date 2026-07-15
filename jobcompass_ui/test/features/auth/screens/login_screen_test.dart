import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobcompass_ui/core/localization/app_localizations.dart';
import 'package:jobcompass_ui/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('switches from login to registration mode', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AppStrings(language: AppLanguage.english, child: LoginScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create a new account'), findsOneWidget);

    await tester.tap(find.text('Create a new account'));
    await tester.pump();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
  });
}
