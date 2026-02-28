import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../products/domain/product.dart';
import '../domain/inventory_transaction.dart';
import 'inventory_providers.dart';

class InventoryHistoryScreen extends ConsumerWidget {
	final Product product;

	const InventoryHistoryScreen({super.key, required this.product});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final transactionsAsync = ref.watch(inventoryHistoryProvider(product.id));

		return Scaffold(
			backgroundColor: const Color(0xFF1A1A2E),
			appBar: AppBar(
				backgroundColor: const Color(0xFF16213E),
				title: Text('Inventory History - ${product.name}'),
			),
			body: transactionsAsync.when(
				loading: () => const Center(child: CircularProgressIndicator()),
				error: (e, _) => Center(
					child: Text(
						'Error: $e',
						style: const TextStyle(color: Colors.red),
					),
				),
				data: (transactions) {
					if (transactions.isEmpty) {
						return const Center(
							child: Text(
								'No inventory transactions yet',
								style: TextStyle(color: Colors.white54, fontSize: 16),
							),
						);
					}

					return ListView.separated(
						padding: const EdgeInsets.all(16),
						itemCount: transactions.length,
						separatorBuilder: (_, _) => const SizedBox(height: 8),
						itemBuilder: (context, index) {
							final transaction = transactions[index];
							return _InventoryTransactionTile(transaction: transaction);
						},
					);
				},
			),
		);
	}
}

class _InventoryTransactionTile extends StatelessWidget {
	final InventoryTransaction transaction;

	const _InventoryTransactionTile({required this.transaction});

	@override
	Widget build(BuildContext context) {
		final date = DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.createdAt);
		final isNegative = transaction.type == InventoryTransactionType.sale;

		return Card(
			color: const Color(0xFF16213E),
			child: ListTile(
				leading: Icon(
					switch (transaction.type) {
						InventoryTransactionType.sale => Icons.remove_circle,
						InventoryTransactionType.restock => Icons.add_circle,
						InventoryTransactionType.refund => Icons.replay_circle_filled,
					},
					color: isNegative ? Colors.redAccent : Colors.greenAccent,
				),
				title: Text(
					transaction.type.name.toUpperCase(),
					style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
				),
				subtitle: Text(
					'Qty: ${transaction.quantity} • $date${transaction.referenceId == null ? '' : ' • Ref: ${transaction.referenceId}'}',
					style: const TextStyle(color: Colors.white70),
				),
				trailing: Text(
					isNegative ? '-${transaction.quantity}' : '+${transaction.quantity}',
					style: TextStyle(
						color: isNegative ? Colors.redAccent : Colors.greenAccent,
						fontWeight: FontWeight.bold,
						fontSize: 16,
					),
				),
			),
		);
	}
}
