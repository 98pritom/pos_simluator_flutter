import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/mock/mock_payment_service.dart';
import '../../../core/services/mock/mock_drawer_service.dart';
import '../../../core/services/mock/mock_printer_service.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/services/drawer_service.dart';
import '../../cart/domain/cart.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../orders/domain/order.dart' as order_model;
import '../../orders/presentation/order_providers.dart';
import '../../products/presentation/product_providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

// Hardware service providers — swap mock for real via overrides.
final printerServiceProvider = Provider<PrinterService>((ref) => MockPrinterService());
final drawerServiceProvider = Provider<DrawerService>((ref) => MockDrawerService());
final paymentServiceProvider = Provider<MockPaymentService>((ref) => MockPaymentService());

/// Checkout dialog — handles payment selection, processing, receipt.
class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({super.key});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  PaymentType _selectedType = PaymentType.cash;
  bool _processing = false;
  String? _error;
  order_model.Order? _completedOrder;
  String? _receiptText;

  @override
  void initState() {
    super.initState();
    // Apply settings to payment service
    final settings = ref.read(settingsProvider);
    ref.read(paymentServiceProvider).simulateFailures =
        settings['simulate_payment_failures'] == 'true';
  }

  Future<void> _processPayment() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    final cart = ref.read(cartProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final paymentService = ref.read(paymentServiceProvider);
    final result = await paymentService.processPayment(
      type: _selectedType,
      amount: cart.grandTotal,
    );

    if (!result.success) {
      setState(() {
        _processing = false;
        _error = result.errorMessage ?? 'Payment failed';
      });
      return;
    }

    // Save order
    final orderRepo = ref.read(orderRepositoryProvider);
    final order = await orderRepo.createFromCart(
      userId: user.id,
      cart: cart,
      paymentType: _selectedType.name,
    );

    // Generate receipt
    final receipt = _generateReceiptText(order, cart);

    // Print receipt
    final printer = ref.read(printerServiceProvider);
    await printer.printReceipt(receipt);

    // Open drawer on cash payment
    if (_selectedType == PaymentType.cash) {
      final drawer = ref.read(drawerServiceProvider);
      await drawer.openDrawer();
    }

    // Clear cart and refresh dependent state
    ref.read(cartProvider.notifier).clearCart();
    ref.invalidate(ordersListProvider);
    await ref.read(productsControllerProvider.notifier).refresh();

    setState(() {
      _processing = false;
      _completedOrder = order;
      _receiptText = receipt;
    });
  }

  String _generateReceiptText(order_model.Order order, CartState cart) {
    final settings = ref.read(settingsProvider);
    final footer = settings['receipt_footer'] ?? 'Thank you!';
    final currency = settings['currency'] ?? 'USD';
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(order.createdAt);

    final buf = StringBuffer();
    buf.writeln('================================');
    buf.writeln('         POS SIMULATOR          ');
    buf.writeln('================================');
    buf.writeln('Date: $dateStr');
    buf.writeln('Order: ${order.id}');
    buf.writeln('Payment: ${order.paymentType.toUpperCase()}');
    buf.writeln('--------------------------------');

    for (final item in order.items) {
      final name = item.productName.padRight(20);
      final qty = 'x${item.quantity}'.padLeft(4);
      final total = CurrencyFormatter.format(item.total);
      buf.writeln('$name$qty  $total');
    }

    buf.writeln('--------------------------------');
    buf.writeln('Subtotal:     ${CurrencyFormatter.format(order.subtotal).padLeft(12)}');
    if (order.discountAmount > 0) {
      buf.writeln('Discount:    -${CurrencyFormatter.format(order.discountAmount).padLeft(12)}');
    }
    buf.writeln('Tax:          ${CurrencyFormatter.format(order.taxAmount).padLeft(12)}');
    buf.writeln('================================');
    buf.writeln('TOTAL:        ${CurrencyFormatter.format(order.grandTotal).padLeft(12)}');
    buf.writeln('================================');
    buf.writeln('Currency: $currency');
    buf.writeln('');
    buf.writeln(footer);
    buf.writeln('');

    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (_completedOrder != null) {
      return _buildReceiptView();
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('Checkout', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Total Due', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(cart.grandTotal),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment type selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Payment Method',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: PaymentType.values.map((type) {
                final selected = _selectedType == type;
                final icon = switch (type) {
                  PaymentType.cash => Icons.attach_money,
                  PaymentType.card => Icons.credit_card,
                  PaymentType.qr => Icons.qr_code,
                };
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton.icon(
                      onPressed: _processing ? null : () => setState(() => _selectedType = type),
                      icon: Icon(icon, size: 20),
                      label: Text(type.name.toUpperCase()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected ? Colors.green.shade700 : const Color(0xFF16213E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: selected ? Colors.greenAccent : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _processing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _processing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: _processing
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildReceiptView() {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent),
          const SizedBox(width: 8),
          const Text('Payment Complete', style: TextStyle(color: Colors.greenAccent)),
        ],
      ),
      content: SizedBox(
        width: 420,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _receiptText ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
          child: const Text('DONE', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
