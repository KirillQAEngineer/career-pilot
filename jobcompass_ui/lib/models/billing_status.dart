class BillingStatus {
  const BillingStatus({
    required this.hasAnalyticsAccess,
    required this.checkoutAvailable,
    required this.emailVerified,
    required this.priceMinorUnits,
    required this.currency,
    required this.displayPrice,
    required this.latestPaymentStatus,
  });

  final bool hasAnalyticsAccess;
  final bool checkoutAvailable;
  final bool emailVerified;
  final int priceMinorUnits;
  final String currency;
  final String displayPrice;
  final String? latestPaymentStatus;

  String get invoiceAmount => (priceMinorUnits / 100).toStringAsFixed(2);

  factory BillingStatus.fromJson(Map<String, dynamic> json) {
    return BillingStatus(
      hasAnalyticsAccess: json['has_analytics_access'] as bool? ?? false,
      checkoutAvailable: json['checkout_available'] as bool? ?? false,
      emailVerified: json['email_verified'] as bool? ?? false,
      priceMinorUnits: json['price_minor_units'] as int? ?? 125,
      currency: json['currency']?.toString() ?? 'USD',
      displayPrice: json['display_price']?.toString() ?? '99 ₽',
      latestPaymentStatus: json['latest_payment_status']?.toString(),
    );
  }
}

class AnalyticsCheckout {
  const AnalyticsCheckout({
    required this.paymentId,
    required this.confirmationUrl,
    required this.status,
  });

  final String paymentId;
  final String confirmationUrl;
  final String status;

  factory AnalyticsCheckout.fromJson(Map<String, dynamic> json) {
    return AnalyticsCheckout(
      paymentId: json['payment_id']?.toString() ?? '',
      confirmationUrl: json['confirmation_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}
