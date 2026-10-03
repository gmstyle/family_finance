/// On-device receipt OCR capability.
///
/// Android provides a real ML Kit implementation; other platforms use a no-op
/// stub. Screens must branch on [isCaptureSupported] — never on `kIsWeb`.
abstract class ReceiptOcrService {
  /// Whether the current platform can capture/pick an image and run OCR.
  bool get isCaptureSupported;

  /// Runs text recognition on a local image file and returns OCR lines.
  ///
  /// Throws [UnsupportedError] when [isCaptureSupported] is false.
  Future<List<String>> recognizeLines(String imagePath);

  /// Releases native resources (no-op for stubs).
  Future<void> dispose();
}
