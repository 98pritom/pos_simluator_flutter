import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/inventory_transaction.dart';

class InventoryRepository {
	final DatabaseHelper _db;

	InventoryRepository(this._db);

	Future<void> addTransaction(
		InventoryTransaction transaction, {
		DatabaseExecutor? executor,
	}) async {
		if (transaction.quantity <= 0) {
			throw ArgumentError('Transaction quantity must be greater than zero');
		}

		final dbExecutor = executor ?? await _db.database;
		await dbExecutor.insert('inventory_transactions', transaction.toMap());
	}

	Future<void> addByType({
		required String productId,
		required InventoryTransactionType type,
		required int quantity,
		String? referenceId,
		DatabaseExecutor? executor,
		DateTime? createdAt,
	}) async {
		await addTransaction(
			InventoryTransaction(
				id: IdGenerator.generate(),
				productId: productId,
				type: type,
				quantity: quantity,
				createdAt: createdAt ?? DateTime.now(),
				referenceId: referenceId,
			),
			executor: executor,
		);
	}

	Future<List<InventoryTransaction>> getTransactionsByProduct(String productId) async {
		final db = await _db.database;
		final results = await db.query(
			'inventory_transactions',
			where: 'productId = ?',
			whereArgs: [productId],
			orderBy: 'createdAt DESC',
		);
		return results.map((row) => InventoryTransaction.fromMap(row)).toList();
	}

	Future<int> calculateStock(
		String productId, {
		DatabaseExecutor? executor,
	}) async {
		final dbExecutor = executor ?? await _db.database;
		final result = await dbExecutor.rawQuery(
			'''
			SELECT COALESCE(SUM(
				CASE
					WHEN type = 'sale' THEN -quantity
					WHEN type = 'restock' THEN quantity
					WHEN type = 'refund' THEN quantity
					ELSE 0
				END
			), 0) AS stock
			FROM inventory_transactions
			WHERE productId = ?
			''',
			[productId],
		);
		return (result.first['stock'] as num?)?.toInt() ?? 0;
	}

	Future<void> ensureCanSell({
		required String productId,
		required int quantity,
		DatabaseExecutor? executor,
	}) async {
		if (quantity <= 0) {
			throw ArgumentError('Sale quantity must be greater than zero');
		}

		final currentStock = await calculateStock(productId, executor: executor);
		if (currentStock < quantity) {
			throw StateError('Insufficient stock for product $productId');
		}
	}
}
