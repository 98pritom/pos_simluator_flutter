import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(DatabaseHelper.instance);
});

/// Orders list — manually refreshed after new order.
final ordersListProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  return repo.getAll();
});

/// Selected order for detail view.
final selectedOrderProvider = StateProvider<Order?>((ref) => null);
