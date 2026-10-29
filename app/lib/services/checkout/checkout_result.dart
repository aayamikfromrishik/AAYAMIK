/// Fields Razorpay returns after a successful payment; the server verifies them.
class CheckoutResult {
  CheckoutResult({required this.orderId, required this.paymentId, required this.signature});

  final String orderId;
  final String paymentId;
  final String signature;
}
