import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(DatabaseHelper.instance);
});

/// Provides the full product list — refreshed on mutations.
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getAll();
});

/// Search query state.
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered product list based on search query.
final filteredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(productSearchQueryProvider);
  final repo = ref.read(productRepositoryProvider);
  if (query.isEmpty) {
    return repo.getAll();
  }
  return repo.search(query);
});

/// Category filter.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Products filtered by category.
final categoryFilteredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(filteredProductsProvider.future);
  final category = ref.watch(selectedCategoryProvider);
  if (category == null || category.isEmpty) return products;
  return products.where((p) => p.category == category).toList();
});

/// All categories.
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getCategories();
});
