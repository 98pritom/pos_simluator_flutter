import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final double price;
  final String? barcode;
  final String category;
  // Computed from inventory transactions. Not a source-of-truth persisted value.
  final int stock;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.barcode,
    required this.category,
    required this.stock,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      barcode: map['barcode'] as String?,
      category: map['category'] as String? ?? 'General',
      stock: map['stock'] as int? ?? 0,
      active: (map['active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'barcode': barcode,
      'category': category,
      'stock': stock,
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? name,
    double? price,
    String? barcode,
    String? category,
    int? stock,
    bool? active,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, price, barcode, category, stock, active];
}
