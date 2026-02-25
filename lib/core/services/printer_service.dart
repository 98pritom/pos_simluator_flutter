/// Abstract printer interface.
/// Real implementation would send ESC/POS commands to thermal printer.
/// Mock implementation logs output and shows receipt preview.
abstract class PrinterService {
  Future<bool> printReceipt(String receiptData);
  Future<bool> openCashDrawer();
  Future<bool> isConnected();
}
