import '../../../core/database/database_helper.dart';
import '../../../core/utils/id_generator.dart';
import '../../cart/domain/cart.dart';
import '../domain/order.dart';

class OrderRepository {
  final DatabaseHelper _db;

  OrderRepository(this._db);

  /// Create order from cart state. Returns saved order.
  Future<Order> createFromCart({
    required String userId,
    required CartState cart,
    required String paymentType,
  }) async {
    final db = await _db.database;
    final orderId = IdGenerator.orderId();
    final now = DateTime.now();

    final order = Order(
      id: orderId,
      userId: userId,
      subtotal: cart.subtotal,
      taxAmount: cart.taxAmount,
      discountAmount: cart.discountAmount,
      grandTotal: cart.grandTotal,
      paymentType: paymentType,
      status: OrderStatus.completed,
      createdAt: now,
    );

    final items = <OrderItem>[];
    await db.transaction((txn) async {
      await txn.insert('orders', order.toMap());

      for (final cartItem in cart.items) {
        final orderItem = OrderItem(
          id: IdGenerator.generate(),
          orderId: orderId,
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          unitPrice: cartItem.product.price,
          quantity: cartItem.quantity,
          total: cartItem.total,
        );
        items.add(orderItem);
        await txn.insert('order_items', orderItem.toMap());

        // Decrement stock
        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(0, stock - ?), updated_at = ? WHERE id = ?',
          [cartItem.quantity, now.toIso8601String(), cartItem.product.id],
        );
      }
    });

    return Order(
      id: order.id,
      userId: order.userId,
      subtotal: order.subtotal,
      taxAmount: order.taxAmount,
      discountAmount: order.discountAmount,
      grandTotal: order.grandTotal,
      paymentType: order.paymentType,
      status: order.status,
      createdAt: order.createdAt,
      items: items,
    );
  }

  Future<List<Order>> getAll({int limit = 50}) async {
    final db = await _db.database;
    final results = await db.query(
      'orders',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return results.map((m) => Order.fromMap(m)).toList();
  }

  Future<Order?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;

    final items = await db.query('order_items', where: 'order_id = ?', whereArgs: [id]);
    return Order.fromMap(results.first, items.map((m) => OrderItem.fromMap(m)).toList());
  }

  Future<void> markRefunded(String id) async {
    final db = await _db.database;
    await db.update(
      'orders',
      {'status': 'refunded'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
