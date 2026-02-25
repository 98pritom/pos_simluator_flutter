import 'package:equatable/equatable.dart';
import '../../products/domain/product.dart';

/// A single line item in the cart.
class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product.id, quantity];
}

/// Discount can be fixed amount or percentage.
enum DiscountType { fixed, percentage }

class Discount extends Equatable {
  final DiscountType type;
  final double value;

  const Discount({required this.type, required this.value});

  const Discount.none() : type = DiscountType.fixed, value = 0;

  double calculate(double subtotal) {
    if (value <= 0) return 0;
    switch (type) {
      case DiscountType.fixed:
        return value.clamp(0, subtotal);
      case DiscountType.percentage:
        return (subtotal * value / 100).clamp(0, subtotal);
    }
  }

  bool get isEmpty => value <= 0;

  @override
  List<Object?> get props => [type, value];
}

/// Complete cart state — pure data, no side effects.
class CartState extends Equatable {
  final List<CartItem> items;
  final double taxPercent;
  final Discount discount;

  const CartState({
    this.items = const [],
    this.taxPercent = 8.0,
    this.discount = const Discount.none(),
  });

  // ---- Pure business logic calculations ----

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get discountAmount => discount.calculate(subtotal);

  double get taxableAmount => subtotal - discountAmount;

  double get taxAmount => taxableAmount * taxPercent / 100;

  double get grandTotal => taxableAmount + taxAmount;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    double? taxPercent,
    Discount? discount,
  }) {
    return CartState(
      items: items ?? this.items,
      taxPercent: taxPercent ?? this.taxPercent,
      discount: discount ?? this.discount,
    );
  }

  @override
  List<Object?> get props => [items, taxPercent, discount];
}
