import '../../../core/database/database_helper.dart';
import '../../../core/utils/id_generator.dart';
import '../../cart/domain/cart.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/domain/inventory_transaction.dart';
import '../domain/order.dart';

class OrderRepository {
  final DatabaseHelper _db;
  final InventoryRepository _inventoryRepository;

  OrderRepository(this._db, this._inventoryRepository);

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
      for (final cartItem in cart.items) {
        await _inventoryRepository.ensureCanSell(
          productId: cartItem.product.id,
          quantity: cartItem.quantity,
          executor: txn,
        );
      }

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

        await _inventoryRepository.addByType(
          productId: cartItem.product.id,
          type: InventoryTransactionType.sale,
          quantity: cartItem.quantity,
          referenceId: orderId,
          executor: txn,
          createdAt: now,
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
    await db.transaction((txn) async {
      final orderRows = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (orderRows.isEmpty) {
        throw StateError('Order not found');
      }

      final status = orderRows.first['status'] as String?;
      if (status == 'refunded') {
        return;
      }

      final items = await txn.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [id],
      );

      for (final item in items) {
        await _inventoryRepository.addByType(
          productId: item['product_id'] as String,
          type: InventoryTransactionType.refund,
          quantity: item['quantity'] as int,
          referenceId: id,
          executor: txn,
        );
      }

      await txn.update(
        'orders',
        {'status': 'refunded'},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
