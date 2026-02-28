import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';
import '../../../core/utils/currency_formatter.dart';

/// Touch-optimized card for product grid display.
class ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: product.stock > 0 ? const Color(0xFF16213E) : Colors.grey.shade800,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: product.stock > 0 ? onTap : null,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(product.price),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.category,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'x${product.stock}',
                    style: TextStyle(
                      color: product.stock < 10 ? Colors.orange : Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: product.stock < 10 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductRestockDialog extends StatefulWidget {
  final Product product;

  const ProductRestockDialog({super.key, required this.product});

  @override
  State<ProductRestockDialog> createState() => _ProductRestockDialogState();
}

class _ProductRestockDialogState extends State<ProductRestockDialog> {
  final TextEditingController _qtyCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final quantity = int.tryParse(_qtyCtrl.text.trim());
    if (quantity == null || quantity <= 0) {
      setState(() {
        _errorText = 'Quantity must be greater than 0';
      });
      return;
    }

    Navigator.pop(context, quantity);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('Restock Product', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current stock: ${widget.product.stock}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Quantity to add',
                labelStyle: const TextStyle(color: Colors.white70),
                errorText: _errorText,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.greenAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

/// Product management dialog for CRUD operations.
class ProductEditDialog extends ConsumerStatefulWidget {
  final Product? product; // null = create new

  const ProductEditDialog({super.key, this.product});

  @override
  ConsumerState<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends ConsumerState<ProductEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _stockCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? 'General');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _barcodeCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.product == null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text(
        isNew ? 'Add Product' : 'Edit Product',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Name', _nameCtrl),
            _field('Price', _priceCtrl, keyboard: TextInputType.number),
            _field('Barcode', _barcodeCtrl),
            _field('Category', _categoryCtrl),
            _field('Stock', _stockCtrl, keyboard: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = {
              'name': _nameCtrl.text.trim(),
              'price': double.tryParse(_priceCtrl.text) ?? 0,
              'barcode': _barcodeCtrl.text.trim(),
              'category': _categoryCtrl.text.trim(),
              'stock': int.tryParse(_stockCtrl.text) ?? 0,
            };
            Navigator.pop(context, result);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
          child: Text(isNew ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.greenAccent),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
