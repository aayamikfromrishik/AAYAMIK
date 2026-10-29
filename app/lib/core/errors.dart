import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the user closes the Razorpay checkout or the payment fails.
class PaymentCancelled implements Exception {
  PaymentCancelled([this.reason]);
  final String? reason;
}

const _messages = {
  // Database rules
  'CONTACT_INFO_NOT_ALLOWED':
      'Phone numbers, emails, links and "WhatsApp me" are not allowed. Buyers get your contact after they unlock the listing.',
  'NOT_UNLOCKED': 'Unlock this listing to see the contact details.',
  'WAIT_48_HOURS': 'Please give the seller 48 hours to respond before asking for a refund.',
  'REFUND_WINDOW_CLOSED': 'Refunds can only be requested within 7 days of unlocking.',
  'REFUND_ALREADY_REQUESTED': 'You have already asked for a refund for this unlock.',
  'UNLOCK_NOT_FOUND': 'This unlock could not be found.',
  // Server functions
  'NOT_SIGNED_IN': 'Please sign in again.',
  'LISTING_NOT_AVAILABLE': 'This listing is no longer available.',
  'CANNOT_UNLOCK_OWN_LISTING': 'This is your own listing.',
  'ALREADY_UNLOCKED': 'You have already unlocked this listing.',
  'PAYMENT_PROVIDER_ERROR': 'Payment service is not responding. Please try again.',
  'IMAGE_CHECK_UNAVAILABLE': 'Photo check is not available right now. Please try again.',
  'INVALID_SIGNATURE': 'Payment could not be verified. If money was taken, it will be confirmed shortly.',
};

/// Turns any error from Supabase, server functions or the network into a
/// sentence that can be shown to the user.
String friendlyError(Object error) {
  if (error is PaymentCancelled) return 'Payment was cancelled.';
  if (error is TimeoutException) return error.message ?? 'This is taking too long. Please try again.';
  if (error is PostgrestException) {
    if (error.code == '23505') return 'You have already done this.';
    return _messages[error.message] ?? 'Something went wrong. Please try again.';
  }
  if (error is FunctionException) {
    final details = error.details;
    final code = details is Map ? details['error'] : null;
    return _messages[code] ?? 'Something went wrong. Please try again.';
  }
  if (error is AuthException) return error.message;
  if (error is StorageException) return 'Upload failed. Please check your internet and try again.';
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException')) {
    return 'No internet connection.';
  }
  return 'Something went wrong. Please try again.';
}
