import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../../core/errors.dart';
import 'checkout_result.dart';

/// window.Razorpay from checkout.js (loaded in web/index.html).
@JS('Razorpay')
extension type _Razorpay._(JSObject _) implements JSObject {
  external factory _Razorpay(JSObject options);
  external void open();
}

class RazorpayCheckout {
  /// Opens checkout. Throws [PaymentCancelled] if the buyer closes it.
  /// A failed attempt keeps the checkout open so the buyer can retry.
  Future<CheckoutResult> open(Map<String, Object?> options) {
    if (!globalContext.has('Razorpay')) {
      return Future.error(PaymentCancelled('Payment page could not load. Check your internet.'));
    }
    final completer = Completer<CheckoutResult>();
    final opts = options.jsify() as JSObject;

    opts['handler'] = ((JSObject r) {
      if (completer.isCompleted) return;
      completer.complete(CheckoutResult(
        orderId: _str(r, 'razorpay_order_id'),
        paymentId: _str(r, 'razorpay_payment_id'),
        signature: _str(r, 'razorpay_signature'),
      ));
    }).toJS;

    final modal = JSObject();
    modal['ondismiss'] = (() {
      if (!completer.isCompleted) completer.completeError(PaymentCancelled());
    }).toJS;
    opts['modal'] = modal;

    _Razorpay(opts).open();
    return completer.future;
  }

  static String _str(JSObject o, String key) => (o[key] as JSString?)?.toDart ?? '';

  void dispose() {}
}
