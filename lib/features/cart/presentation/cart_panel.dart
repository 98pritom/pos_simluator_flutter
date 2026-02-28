import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cart.dart';
import '../presentation/cart_provider.dart';
import '../../../core/utils/currency_formatter.dart';

/// Cart panel widget — right side of POS layout.
class CartPanel extends ConsumerWidget {
  final VoidCallback onCheckout;

  const CartPanel({super.key, required this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Container(
      color: const Color(0xFF0F3460),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF16213E),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Current Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  Text(
                    '${cart.totalItems} items',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      'No items in cart\nTap a product to add',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemTile(item: item);
                    },
                  ),
          ),

          // Discount button
          if (!cart.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDiscountDialog(context, ref, cart),
                  icon: const Icon(Icons.discount, size: 18),
                  label: Text(
                    cart.discount.isEmpty
                        ? 'Add Discount'
                        : cart.discount.type == DiscountType.percentage
                            ? 'Discount: ${cart.discount.value}%'
                            : 'Discount: ${CurrencyFormatter.format(cart.discount.value)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ),

          // Totals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                _totalRow('Subtotal', cart.subtotal),
                if (!cart.discount.isEmpty)
                  _totalRow('Discount', -cart.discountAmount, color: Colors.orange),
                _totalRow('Tax (${cart.taxPercent}%)', cart.taxAmount),
                const Divider(color: Colors.white24),
                _totalRow('TOTAL', cart.grandTotal, isBold: true, fontSize: 22),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: cart.isEmpty
                            ? null
                            : () => ref.read(cartProvider.notifier).clearCart(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('CLEAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: cart.isEmpty ? null : onCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'CHECKOUT',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {
    bool isBold = false,
    double fontSize = 15,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, WidgetRef ref, CartState cart) {
    final amountCtrl = TextEditingController();
    var type = DiscountType.percentage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Apply Discount', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('%'),
                    selected: type == DiscountType.percentage,
                    onSelected: (_) => setDialogState(() => type = DiscountType.percentage),
                    selectedColor: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('\$'),
                    selected: type == DiscountType.fixed,
                    onSelected: (_) => setDialogState(() => type = DiscountType.fixed),
                    selectedColor: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: type == DiscountType.percentage ? 'Percentage' : 'Amount',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearDiscount();
                Navigator.pop(ctx);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(amountCtrl.text) ?? 0;
                if (value > 0) {
                  ref.read(cartProvider.notifier).setDiscount(
                    Discount(type: type, value: value),
                  );
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual cart line item with quantity controls.
class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(cartProvider.notifier).removeItem(item.product.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    CurrencyFormatter.format(item.product.price),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Quantity controls
            Row(
              children: [
                _qtyButton(Icons.remove, () {
                  ref.read(cartProvider.notifier).updateQuantity(
                    item.product.id,
                    item.quantity - 1,
                  );
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _qtyButton(Icons.add, () {
                  if (item.quantity >= item.product.stock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Insufficient stock for ${item.product.name}'),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  ref.read(cartProvider.notifier).updateQuantity(
                    item.product.id,
                    item.quantity + 1,
                  );
                }),
              ],
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(
                CurrencyFormatter.format(item.total),
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        iconSize: 18,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
