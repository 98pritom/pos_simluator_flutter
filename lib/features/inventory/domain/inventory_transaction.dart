import 'package:equatable/equatable.dart';

enum InventoryTransactionType { sale, restock, refund }

class InventoryTransaction extends Equatable {
	final String id;
	final String productId;
	final InventoryTransactionType type;
	final int quantity;
	final DateTime createdAt;
	final String? referenceId;

	const InventoryTransaction({
		required this.id,
		required this.productId,
		required this.type,
		required this.quantity,
		required this.createdAt,
		this.referenceId,
	}) : assert(quantity > 0, 'Quantity must be positive');

	factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
		return InventoryTransaction(
			id: map['id'] as String,
			productId: map['productId'] as String,
			type: InventoryTransactionType.values.firstWhere(
				(value) => value.name == map['type'],
				orElse: () => InventoryTransactionType.restock,
			),
			quantity: map['quantity'] as int,
			createdAt: DateTime.parse(map['createdAt'] as String),
			referenceId: map['referenceId'] as String?,
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'productId': productId,
			'type': type.name,
			'quantity': quantity,
			'createdAt': createdAt.toIso8601String(),
			'referenceId': referenceId,
		};
	}

	@override
	List<Object?> get props => [id, productId, type, quantity, createdAt, referenceId];
}
