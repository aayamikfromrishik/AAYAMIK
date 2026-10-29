import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/demo_repository.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'checkout/checkout.dart';

/// Pays the unlock fee for a listing through Razorpay.
///
/// 1. Server creates a Razorpay order for the exact fee.
/// 2. Razorpay checkout opens (UPI, cards, netbanking).
/// 3. Server verifies the payment and unlocks the contact.
class UnlockPayment {
  final _checkout = RazorpayCheckout();

  SupabaseClient get _db => Supabase.instance.client;

  /// Completes when the contact is unlocked. Throws PaymentCancelled if the
  /// buyer backs out, or another error if something fails.
  Future<void> unlock(Listing listing, {String? buyerPhone}) async {
    final repo = Repository.instance;
    if (repo is DemoRepository) return repo.fakeUnlock(listing.id);

    final orderRes = await _db.functions.invoke('create-unlock-order', body: {'listing_id': listing.id});
    final order = orderRes.data as Map<String, dynamic>;

    final payment = await _checkout.open({
      'key': order['key_id'],
      'order_id': order['order_id'],
      'amount': order['amount_paise'],
      'currency': order['currency'],
      'name': 'BAAKI BUILD',
      'description': 'Unlock contact: ${listing.title}',
      'prefill': {'contact': ?buyerPhone},
      'theme': {'color': '#E8590C'},
    });

    final verifyRes = await _db.functions.invoke('verify-unlock-payment', body: {
      'razorpay_order_id': payment.orderId,
      'razorpay_payment_id': payment.paymentId,
      'razorpay_signature': payment.signature,
    });

    // 202: Razorpay is still capturing the payment; the webhook will finish it.
    if (verifyRes.status == 202) {
      for (var i = 0; i < 15; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (await Repository.instance.hasUnlocked(listing.id)) return;
      }
      throw TimeoutException('Payment received. The contact will unlock within a few minutes.');
    }
  }

  void dispose() => _checkout.dispose();
}
