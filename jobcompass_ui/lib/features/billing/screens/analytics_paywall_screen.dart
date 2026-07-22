import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/url_launcher_utils.dart';
import '../../../providers/billing_provider.dart';

class AnalyticsPaywallScreen extends ConsumerStatefulWidget {
  const AnalyticsPaywallScreen({super.key});

  @override
  ConsumerState<AnalyticsPaywallScreen> createState() =>
      _AnalyticsPaywallScreenState();
}

class _AnalyticsPaywallScreenState
    extends ConsumerState<AnalyticsPaywallScreen> {
  bool _openingPayment = false;
  bool _checkingPayment = false;

  Future<void> _buy() async {
    setState(() => _openingPayment = true);
    final checkout = await ref.read(billingProvider.notifier).createCheckout();

    if (!mounted) {
      return;
    }

    var opened = false;
    if (checkout != null && checkout.confirmationUrl.isNotEmpty) {
      opened = await openExternalUrl(checkout.confirmationUrl);
    }

    if (!mounted) {
      return;
    }

    setState(() => _openingPayment = false);

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('payment_open_failed'))),
      );
    }
  }

  Future<void> _checkPayment() async {
    setState(() => _checkingPayment = true);
    final active = await ref.read(billingProvider.notifier).refreshPayment();

    if (!mounted) {
      return;
    }

    setState(() => _checkingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(active ? 'analytics_access_active' : 'payment_pending'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = ref.watch(billingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('crm'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: billing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(billingProvider),
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('retry')),
          ),
        ),
        data: (status) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics_outlined, size: 52),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('analytics_lifetime_title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('analytics_lifetime_body'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context
                            .tr('payment_invoice_amount')
                            .replaceAll('{amount}', status.invoiceAmount)
                            .replaceAll('{currency}', status.currency),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (!status.emailVerified)
                        Text(
                          context.tr('payment_requires_verified_email'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      else if (!status.checkoutAvailable)
                        Text(
                          context.tr('payment_unavailable'),
                          textAlign: TextAlign.center,
                        )
                      else
                        FilledButton.icon(
                          onPressed: _openingPayment ? null : _buy,
                          icon: _openingPayment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_open_outlined),
                          label: Text(
                            context
                                .tr('buy_analytics_crypto')
                                .replaceAll('{price}', status.displayPrice),
                          ),
                        ),
                      if (_canCheck(status.latestPaymentStatus)) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _checkingPayment ? null : _checkPayment,
                          icon: _checkingPayment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(context.tr('check_payment')),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        context.tr('payment_security_note'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canCheck(String? paymentStatus) {
    return const {
      'pending',
      'waiting',
      'confirming',
      'confirmed',
      'sending',
      'partially_paid',
    }.contains(paymentStatus);
  }
}
