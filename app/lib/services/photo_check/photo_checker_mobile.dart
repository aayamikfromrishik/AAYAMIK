import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/contact_filter.dart';

/// On-phone photo check, run before upload so the seller gets instant
/// feedback. The server checks every photo again; this one only saves time.
class PhotoChecker {
  final _faces = FaceDetector(options: FaceDetectorOptions(minFaceSize: 0.05));
  final _codes = BarcodeScanner();
  final _text = TextRecognizer();

  /// Returns null if the photo looks fine, otherwise the reason it can't be used.
  Future<String?> check(String filePath) async {
    final image = InputImage.fromFilePath(filePath);

    if ((await _faces.processImage(image)).isNotEmpty) {
      return "Photos with people's faces are not allowed. Please photograph only the material.";
    }
    if ((await _codes.processImage(image)).isNotEmpty) {
      return 'Photos with QR codes or barcodes are not allowed.';
    }
    final text = await _text.processImage(image);
    if (containsContactInfo(text.text)) {
      return 'This photo seems to show a phone number, email or website. Please use a photo without contact details.';
    }
    return null;
  }

  void dispose() {
    _faces.close();
    _codes.close();
    _text.close();
  }
}
