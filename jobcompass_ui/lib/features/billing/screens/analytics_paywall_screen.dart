import 'dart:async';

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
  final _amountController = TextEditingController(text: '1');
  bool _openingPayment = false;
  String? _amountError;
  Timer? _paymentStatusTimer;

  @override
  void initState() {
    super.initState();
    _paymentStatusTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) =>
          unawaited(ref.read(billingProvider.notifier).refreshStatusSilently()),
    );
  }

  @override
  void dispose() {
    _paymentStatusTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    final amount = _validatedAmount();

    if (amount == null) {
      setState(() => _amountError = context.tr('payment_amount_invalid'));
      return;
    }

    setState(() {
      _amountError = null;
      _openingPayment = true;
    });
    final checkout = await ref
        .read(billingProvider.notifier)
        .createCheckout(amountUsdt: amount);

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

  String? _validatedAmount() {
    final normalized = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    final hasSupportedPrecision = RegExp(
      r'^\d+(?:\.\d{1,2})?$',
    ).hasMatch(normalized);

    if (!hasSupportedPrecision || amount == null || amount < 1) {
      return null;
    }

    if (amount > 100000) {
      return null;
    }

    return normalized;
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
                        context.tr('payment_custom_amount_hint'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        enabled: !_openingPayment,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('payment_amount_label'),
                          helperText: context.tr('payment_amount_helper'),
                          errorText: _amountError,
                          suffixText: 'USDT',
                          prefixIcon: const Icon(Icons.payments_outlined),
                        ),
                        onChanged: (_) {
                          if (_amountError != null) {
                            setState(() => _amountError = null);
                          }
                        },
                        onSubmitted: (_) {
                          if (!_openingPayment &&
                              status.emailVerified &&
                              status.checkoutAvailable) {
                            _buy();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.currency_bitcoin_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.tr('payment_usdt_trc20_notice'),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                          label: Text(context.tr('buy_analytics_crypto')),
                        ),
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
}
