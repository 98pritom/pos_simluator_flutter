import 'dart:developer' as dev;
import '../printer_service.dart';
import '../../config/app_config.dart';

/// Simulator printer — logs ESC/POS-style output, returns success.
class MockPrinterService implements PrinterService {
  @override
  Future<bool> printReceipt(String receiptData) async {
    await Future.delayed(AppConfig.mockPrintDelay);

    // Log ESC/POS-style output to console
    dev.log(
      '\n========== ESC/POS OUTPUT ==========\n'
      '$receiptData'
      '\n====================================\n',
      name: 'MockPrinter',
    );

    return true;
  }

  @override
  Future<bool> openCashDrawer() async {
    await Future.delayed(AppConfig.mockDrawerDelay);
    dev.log('ESC/POS: OPEN CASH DRAWER (\\x1B\\x70\\x00)', name: 'MockPrinter');
    return true;
  }

  @override
  Future<bool> isConnected() async => true;
}
