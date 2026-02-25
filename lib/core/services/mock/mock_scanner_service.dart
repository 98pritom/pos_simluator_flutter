import 'dart:async';
import '../scanner_service.dart';

/// Simulator scanner — exposes a stream fed by manual/keyboard input.
class MockScannerService implements ScannerService {
  final _barcodeController = StreamController<String>.broadcast();

  @override
  Stream<String> get barcodeStream => _barcodeController.stream;

  @override
  void manualScan(String barcode) {
    final trimmed = barcode.trim();
    if (trimmed.isNotEmpty) {
      _barcodeController.add(trimmed);
    }
  }

  @override
  void dispose() {
    _barcodeController.close();
  }
}
