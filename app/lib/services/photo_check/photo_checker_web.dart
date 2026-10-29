/// Browser stand-in for the ML Kit photo check. Photos are still checked by
/// the server after upload, so nothing is skipped, only the instant feedback.
class PhotoChecker {
  Future<String?> check(String filePath) async => null;

  void dispose() {}
}
