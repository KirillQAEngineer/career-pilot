import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/core/localization/app_localizations.dart';
import 'package:jobcompass_ui/features/billing/screens/analytics_paywall_screen.dart';
import 'package:jobcompass_ui/features/billing/services/billing_api.dart';
import 'package:jobcompass_ui/features/billing/widgets/analytics_promo_banner.dart';
import 'package:jobcompass_ui/models/billing_status.dart';
import 'package:jobcompass_ui/providers/billing_provider.dart';

class _FakeBillingApi extends BillingApi {
  _FakeBillingApi() : super(Dio());

  @override
  Future<BillingStatus> getStatus() async {
    return BillingStatus(
      hasAnalyticsAccess: false,
      checkoutAvailable: true,
      emailVerified: true,
      priceMinorUnits: 100,
      currency: 'USD',
      displayPrice: 'from 1 USDT',
      latestPaymentStatus: 'pending',
    );
  }
}

void main() {
  testWidgets('English paywall uses USDT and has no manual payment check', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [billingApiProvider.overrideWithValue(_FakeBillingApi())],
        child: const AppStrings(
          language: AppLanguage.english,
          child: MaterialApp(home: AnalyticsPaywallScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analytics forever — from 1 USDT'), findsOneWidget);
    expect(find.text('Continue to USDT payment'), findsOneWidget);
    expect(find.textContaining('I paid'), findsNothing);

    final amountField = find.byType(TextField);
    await tester.enterText(amountField, '0.99');
    final paymentButton = find.text('Continue to USDT payment');
    await tester.ensureVisible(paymentButton);
    await tester.tap(paymentButton);
    await tester.pump();

    expect(find.textContaining('Enter an amount from 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('English Analytics banner advertises USDT', (tester) async {
    await tester.pumpWidget(
      const AppStrings(
        language: AppLanguage.english,
        child: MaterialApp(
          home: Scaffold(body: AnalyticsPromoBanner(onOpen: _noop)),
        ),
      ),
    );

    expect(find.textContaining('1 USDT'), findsOneWidget);
    expect(find.textContaining('99 ₽'), findsNothing);
  });

  testWidgets('Russian paywall and banner use the same USDT price', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [billingApiProvider.overrideWithValue(_FakeBillingApi())],
        child: const AppStrings(
          language: AppLanguage.russian,
          child: MaterialApp(home: AnalyticsPaywallScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Аналитика навсегда — от 1 USDT'), findsOneWidget);
    expect(find.text('Перейти к оплате USDT'), findsOneWidget);
    expect(find.textContaining('99 ₽'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void _noop() {}
