import '../domain/receipt_ocr_service.dart';
import 'receipt_ocr_factory_stub.dart'
    if (dart.library.io) 'receipt_ocr_factory_io.dart'
    as impl;

/// Platform-selected OCR service (Android ML Kit, stub elsewhere).
ReceiptOcrService createReceiptOcrService() => impl.createReceiptOcrService();
