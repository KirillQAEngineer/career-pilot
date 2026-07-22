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

  Future<AnalyticsCheckout?> createCheckout() async {
    try {
      return await _api.createCheckout();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> refreshPayment() async {
    try {
      final status = await _api.refreshPayment();
      state = AsyncData(status);

      if (status.hasAnalyticsAccess) {
        ref.invalidate(currentUserProvider);
      }

      return status.hasAnalyticsAccess;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final billingProvider = AsyncNotifierProvider<BillingNotifier, BillingStatus>(
  BillingNotifier.new,
);
