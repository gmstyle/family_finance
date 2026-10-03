import '../domain/receipt_ocr_service.dart';

/// No-op OCR for web and non-Android platforms.
class StubReceiptOcrService implements ReceiptOcrService {
  @override
  bool get isCaptureSupported => false;

  @override
  Future<List<String>> recognizeLines(String imagePath) {
    throw UnsupportedError('Receipt OCR capture is only available on Android.');
  }

  @override
  Future<void> dispose() async {}
}
