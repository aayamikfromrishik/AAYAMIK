// The on-device check uses ML Kit, which only exists on Android and iOS.
// In the browser the server-side check (moderate-image) is the only one.
export 'photo_checker_web.dart' if (dart.library.io) 'photo_checker_mobile.dart';
