/// Abstract barcode scanner interface.
/// Real implementation would listen to USB/Bluetooth HID device.
/// Mock implementation uses keyboard input.
abstract class ScannerService {
  /// Stream of scanned barcodes.
  Stream<String> get barcodeStream;

  /// Manually submit a barcode (debug/simulator mode).
  void manualScan(String barcode);

  /// Dispose resources.
  void dispose();
}
