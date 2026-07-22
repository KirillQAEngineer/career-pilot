import 'package:dio/dio.dart';

import '../../../models/billing_status.dart';

class BillingApi {
  const BillingApi(this._dio);

  final Dio _dio;

  Future<BillingStatus> getStatus() async {
    final response = await _dio.get('/billing/me');
    return BillingStatus.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AnalyticsCheckout> createCheckout({required String amountUsdt}) async {
    final response = await _dio.post(
      '/billing/analytics-lifetime/checkout',
      data: {'amount_usdt': amountUsdt},
    );
    return AnalyticsCheckout.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
