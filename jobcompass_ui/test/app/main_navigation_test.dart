import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/app/app.dart';
import 'package:jobcompass_ui/core/localization/app_localizations.dart';
import 'package:jobcompass_ui/models/account_user.dart';
import 'package:jobcompass_ui/providers/account_provider.dart';
import 'package:jobcompass_ui/providers/profile_provider.dart';

Future<void> _pumpNavigation(
  WidgetTester tester, {
  required Size size,
  required bool isAdmin,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) async => AccountUser(
            id: '11111111-1111-4111-8111-111111111111',
            email: 'user@example.com',
            fullName: 'Mobile User',
            isAdmin: isAdmin,
            createdAt: DateTime.utc(2026, 7, 22),
          ),
        ),
        profileProvider.overrideWith((ref) async => null),
      ],
      child: const MaterialApp(
        home: AppStrings(
          language: AppLanguage.english,
          child: MainNavigation(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('narrow admin navigation stays compact without overflow', (
    tester,
  ) async {
    await _pumpNavigation(tester, size: const Size(360, 780), isAdmin: true);

    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));

    expect(navigation.destinations, hasLength(6));
    expect(
      navigation.labelBehavior,
      NavigationDestinationLabelBehavior.onlyShowSelected,
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide layout uses a navigation rail', (tester) async {
    await _pumpNavigation(tester, size: const Size(1200, 800), isAdmin: false);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
