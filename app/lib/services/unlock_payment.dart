import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../data/models.dart';
import '../data/repository.dart';

/// Pays the unlock fee for a listing through Razorpay.
///
/// 1. Server creates a Razorpay order for the exact fee.
/// 2. Razorpay checkout opens on the phone (UPI, cards, netbanking).
/// 3. Server verifies the payment and unlocks the contact.
class UnlockPayment {
  UnlockPayment() {
    _razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  final _razorpay = Razorpay();
  Completer<PaymentSuccessResponse>? _pending;

  SupabaseClient get _db => Supabase.instance.client;

  /// Completes when the contact is unlocked. Throws [PaymentCancelled] if the
  /// buyer backs out, or another error if something fails.
  Future<void> unlock(Listing listing, {String? buyerPhone}) async {
    final orderRes = await _db.functions.invoke('create-unlock-order', body: {'listing_id': listing.id});
    final order = orderRes.data as Map<String, dynamic>;

    _pending = Completer<PaymentSuccessResponse>();
    _razorpay.open({
      'key': order['key_id'],
      'order_id': order['order_id'],
      'amount': order['amount_paise'],
      'currency': order['currency'],
      'name': 'BAAKI BUILD',
      'description': 'Unlock contact: ${listing.title}',
      'prefill': {'contact': ?buyerPhone},
      'theme': {'color': '#E65100'},
    });
    final payment = await _pending!.future;

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

  void _onSuccess(PaymentSuccessResponse response) => _pending?.complete(response);

  void _onError(PaymentFailureResponse response) =>
      _pending?.completeError(PaymentCancelled(response.message));

  void dispose() => _razorpay.clear();
}
