import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/errors.dart';
import 'checkout_result.dart';

class RazorpayCheckout {
  RazorpayCheckout() {
    _razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  final _razorpay = Razorpay();
  Completer<CheckoutResult>? _pending;

  /// Opens checkout. Throws [PaymentCancelled] if the buyer backs out or the payment fails.
  Future<CheckoutResult> open(Map<String, Object?> options) {
    _pending = Completer<CheckoutResult>();
    _razorpay.open(options);
    return _pending!.future;
  }

  void _onSuccess(PaymentSuccessResponse r) => _pending?.complete(
      CheckoutResult(orderId: r.orderId ?? '', paymentId: r.paymentId ?? '', signature: r.signature ?? ''));

  void _onError(PaymentFailureResponse r) => _pending?.completeError(PaymentCancelled(r.message));

  void dispose() => _razorpay.clear();
}
