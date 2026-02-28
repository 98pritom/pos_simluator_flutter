import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../../inventory/domain/inventory_transaction.dart';
import '../../inventory/presentation/inventory_providers.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(DatabaseHelper.instance);
});

class ProductsController extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    return ref.read(productRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).getAll(),
    );
  }

  Future<void> addProduct(Product product) async {
    final initialStock = product.stock;
    final productToInsert = product.copyWith(stock: 0);

    await ref.read(productRepositoryProvider).insert(productToInsert);

    if (initialStock > 0) {
      await ref.read(inventoryRepositoryProvider).addByType(
        productId: product.id,
        type: InventoryTransactionType.restock,
        quantity: initialStock,
        referenceId: 'initial-stock',
        createdAt: product.createdAt,
      );
    }

    await refresh();
  }

  Future<void> restockProduct(String productId, int quantity) async {
    if (quantity <= 0) {
      throw ArgumentError('Restock quantity must be greater than zero');
    }

    await ref.read(inventoryNotifierProvider.notifier).addTransaction(
      productId: productId,
      type: InventoryTransactionType.restock,
      quantity: quantity,
    );
    await refresh();
  }
}

/// Single source of truth for product list in memory.
final productsControllerProvider =
    AsyncNotifierProvider<ProductsController, List<Product>>(
      ProductsController.new,
    );

/// Backward-compatible alias used across the app.
final productListProvider = productsControllerProvider;

/// Search query state.
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered product list based on search query.
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final query = ref.watch(productSearchQueryProvider).trim().toLowerCase();
  final productsAsync = ref.watch(productListProvider);

  return productsAsync.whenData((products) {
    if (query.isEmpty) return products;
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              (p.barcode?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  });
});

/// Category filter.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Products filtered by category.
final categoryFilteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final filteredAsync = ref.watch(filteredProductsProvider);
  final category = ref.watch(selectedCategoryProvider);

  return filteredAsync.whenData((products) {
    if (category == null || category.isEmpty) return products;
    return products.where((p) => p.category == category).toList();
  });
});

/// All categories.
final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final productsAsync = ref.watch(productListProvider);

  return productsAsync.whenData((products) {
    final categories = products
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  });
});
