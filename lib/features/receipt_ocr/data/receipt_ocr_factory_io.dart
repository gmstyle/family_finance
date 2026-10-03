import 'dart:io' show Platform;

import '../domain/receipt_ocr_service.dart';
import 'receipt_ocr_service_android.dart';
import 'receipt_ocr_service_stub.dart';

ReceiptOcrService createReceiptOcrService() {
  if (Platform.isAndroid) {
    return AndroidReceiptOcrService();
  }
  return StubReceiptOcrService();
}
