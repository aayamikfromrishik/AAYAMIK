// Razorpay checkout: the native SDK on Android/iOS, checkout.js in the browser.
export 'checkout_result.dart';
export 'checkout_web.dart' if (dart.library.io) 'checkout_mobile.dart';
