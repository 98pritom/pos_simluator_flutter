import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_transaction.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
	return InventoryRepository(DatabaseHelper.instance);
});

class InventoryNotifier extends AsyncNotifier<void> {
	@override
	Future<void> build() async {}

	Future<void> addTransaction({
		required String productId,
		required InventoryTransactionType type,
		required int quantity,
		String? referenceId,
	}) async {
		state = const AsyncLoading();
		state = await AsyncValue.guard(() async {
			await ref.read(inventoryRepositoryProvider).addByType(
				productId: productId,
				type: type,
				quantity: quantity,
				referenceId: referenceId,
			);
			ref.invalidate(inventoryHistoryProvider(productId));
		});
	}

	Future<int> calculateStock(String productId) {
		return ref.read(inventoryRepositoryProvider).calculateStock(productId);
	}
}

final inventoryNotifierProvider = AsyncNotifierProvider<InventoryNotifier, void>(
	InventoryNotifier.new,
);

final inventoryHistoryProvider =
		FutureProvider.family<List<InventoryTransaction>, String>((ref, productId) {
			return ref.read(inventoryRepositoryProvider).getTransactionsByProduct(productId);
		});
