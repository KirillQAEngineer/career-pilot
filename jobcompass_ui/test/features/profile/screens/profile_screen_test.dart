import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/core/localization/app_localizations.dart';
import 'package:jobcompass_ui/features/profile/screens/edit_profile_screen.dart';
import 'package:jobcompass_ui/features/profile/screens/profile_screen.dart';
import 'package:jobcompass_ui/models/account_user.dart';
import 'package:jobcompass_ui/models/profile.dart';
import 'package:jobcompass_ui/providers/account_provider.dart';
import 'package:jobcompass_ui/providers/profile_provider.dart';

void main() {
  testWidgets('profile fields open the editor focused on the selected field', (
    tester,
  ) async {
    const profile = Profile(
      id: 1,
      profession: 'QA Engineer',
      level: 'Middle',
      skills: 'API Testing, SQL',
      technologies: 'Postman, Docker',
      englishLevel: 'B2',
      preferredRoles: 'QA Engineer, Test Engineer',
      resumeText: 'Resume',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) async => profile),
          currentUserProvider.overrideWith(
            (ref) async => AccountUser(
              id: '11111111-1111-4111-8111-111111111111',
              email: 'qa@example.com',
              fullName: 'QA User',
              isAdmin: false,
              emailVerified: true,
              createdAt: DateTime.utc(2026, 7, 23),
            ),
          ),
        ],
        child: const AppStrings(
          language: AppLanguage.english,
          child: MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsNothing);

    await tester.tap(find.text('Skills'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(
      tester
          .widget<EditProfileScreen>(find.byType(EditProfileScreen))
          .initialField,
      ProfileEditField.skills,
    );
    expect(find.text(profile.skills), findsOneWidget);
  });
}
