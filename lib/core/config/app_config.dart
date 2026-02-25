/// App-wide constants. No magic numbers in feature code.
class AppConfig {
  AppConfig._();

  static const String appName = 'POS Simulator';
  static const String appVersion = '1.0.0';

  // Default settings
  static const double defaultTaxPercent = 8.0;
  static const String defaultCurrency = 'USD';
  static const String defaultReceiptFooter = 'Thank you for your purchase!';

  // Simulated hardware delays
  static const Duration mockPrintDelay = Duration(milliseconds: 800);
  static const Duration mockPaymentDelay = Duration(seconds: 2);
  static const Duration mockDrawerDelay = Duration(milliseconds: 500);
  static const Duration mockScanDelay = Duration(milliseconds: 300);

  // UI
  static const double productGridItemWidth = 140.0;
  static const double productGridItemHeight = 120.0;
}
