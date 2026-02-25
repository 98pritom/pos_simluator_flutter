import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double total;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.total,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      total: (map['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'total': total,
    };
  }

  @override
  List<Object?> get props => [id, orderId, productId, quantity];
}

enum OrderStatus { completed, refunded }

class Order extends Equatable {
  final String id;
  final String userId;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double grandTotal;
  final String paymentType;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.userId,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentType,
    this.status = OrderStatus.completed,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromMap(Map<String, dynamic> map, [List<OrderItem>? items]) {
    return Order(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      grandTotal: (map['grand_total'] as num).toDouble(),
      paymentType: map['payment_type'] as String,
      status: map['status'] == 'refunded' ? OrderStatus.refunded : OrderStatus.completed,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'grand_total': grandTotal,
      'payment_type': paymentType,
      'status': status == OrderStatus.refunded ? 'refunded' : 'completed',
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, grandTotal, status, createdAt];
}
