import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/receipt_ocr_service.dart';

/// ML Kit on-device text recognition (Android).
class AndroidReceiptOcrService implements ReceiptOcrService {
  AndroidReceiptOcrService({TextRecognizer? recognizer})
    : _recognizer =
          recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  bool get isCaptureSupported => true;

  @override
  Future<List<String>> recognizeLines(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    final lines = <String>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) lines.add(text);
      }
    }
    return lines;
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
