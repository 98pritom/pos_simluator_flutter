import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/domain/product.dart';
import '../domain/cart.dart';

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

/// Cart operations — all mutations go through here.
/// Business logic is testable via CartState's pure calculations.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void setTaxPercent(double percent) {
    state = state.copyWith(taxPercent: percent);
  }

  /// Add product to cart. If barcode already exists, increment quantity.
  void addProduct(Product product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state.items);
      final existing = updated[existingIndex];
      updated[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, quantity: 1)],
      );
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final updated = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void setDiscount(Discount discount) {
    state = state.copyWith(discount: discount);
  }

  void clearDiscount() {
    state = state.copyWith(discount: const Discount.none());
  }

  void clearCart() {
    state = const CartState();
  }

  /// Restore cart after payment — set tax from settings.
  void initWithTax(double taxPercent) {
    if (state.taxPercent != taxPercent) {
      state = state.copyWith(taxPercent: taxPercent);
    }
  }
}
