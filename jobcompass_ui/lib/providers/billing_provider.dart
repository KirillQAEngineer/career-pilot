import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/billing/services/billing_api.dart';
import '../models/billing_status.dart';
import 'account_provider.dart';

final billingApiProvider = Provider<BillingApi>(
  (ref) => BillingApi(ApiClient.dio),
);

class BillingNotifier extends AsyncNotifier<BillingStatus> {
  BillingApi get _api => ref.read(billingApiProvider);

  @override
  Future<BillingStatus> build() => _api.getStatus();

  Future<AnalyticsCheckout?> createCheckout({
    required String amountUsdt,
  }) async {
    try {
      return await _api.createCheckout(amountUsdt: amountUsdt);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<void> refreshStatusSilently() async {
    try {
      final status = await _api.getStatus();
      state = AsyncData(status);

      if (status.hasAnalyticsAccess) {
        ref.invalidate(currentUserProvider);
      }
    } catch (_) {
      // The next timer tick retries without replacing the paywall with an
      // error screen when the backend is temporarily waking up.
    }
  }
}

final billingProvider = AsyncNotifierProvider<BillingNotifier, BillingStatus>(
  BillingNotifier.new,
);
