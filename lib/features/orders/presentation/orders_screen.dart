import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order.dart';
import 'order_providers.dart';
import '../../products/presentation/product_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Order History', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ordersListProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders yet', style: TextStyle(color: Colors.white38, fontSize: 18)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) => _OrderTile(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  final Order order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('MMM dd, yyyy – hh:mm a').format(order.createdAt);
    final isRefunded = order.status == OrderStatus.refunded;

    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              order.id,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            if (isRefunded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('REFUNDED', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
          ],
        ),
        subtitle: Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(order.grandTotal),
              style: TextStyle(
                color: isRefunded ? Colors.red : Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              order.paymentType.toUpperCase(),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        onTap: () async {
          final repo = ref.read(orderRepositoryProvider);
          final detailed = await repo.getById(order.id);
          if (detailed != null && context.mounted) {
            _showOrderDetail(context, ref, detailed);
          }
        },
      ),
    );
  }

  void _showOrderDetail(BuildContext context, WidgetRef ref, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Order ${order.id}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} x${item.quantity}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(item.total),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )),
              const Divider(color: Colors.white24),
              _detailRow('Subtotal', order.subtotal),
              if (order.discountAmount > 0) _detailRow('Discount', -order.discountAmount),
              _detailRow('Tax', order.taxAmount),
              const Divider(color: Colors.white24),
              _detailRow('Total', order.grandTotal, bold: true),
            ],
          ),
        ),
        actions: [
          if (order.status != OrderStatus.refunded)
            TextButton(
              onPressed: () async {
                await ref.read(orderRepositoryProvider).markRefunded(order.id);
                ref.invalidate(ordersListProvider);
                await ref.read(productsControllerProvider.notifier).refresh();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('REFUND', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: Colors.white70,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          )),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: Colors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
