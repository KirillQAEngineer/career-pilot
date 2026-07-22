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

  testWidgets('password remains editable after minimum length error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AppStrings(language: AppLanguage.english, child: LoginScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a new account'));
    await tester.pump();

    final passwordField = find.byType(TextFormField).at(2);
    final confirmationField = find.byType(TextFormField).at(3);
    await tester.enterText(passwordField, '12345678');
    await tester.enterText(confirmationField, '12345678');
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Password must be at least 9 characters'), findsOneWidget);
    final passwordEditor = find.descendant(
      of: passwordField,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(passwordEditor).focusNode.hasFocus,
      true,
    );

    await tester.enterText(passwordField, '123456789');
    await tester.pump();

    expect(
      tester.widget<EditableText>(passwordEditor).controller.text,
      '123456789',
    );
  });
}
