import '../../../core/database/database_helper.dart';
import '../domain/product.dart';

class ProductRepository {
  final DatabaseHelper _db;

  ProductRepository(this._db);

  Future<List<Product>> getAll({bool activeOnly = true}) async {
    final db = await _db.database;
    final results = await db.query(
      'products',
      where: activeOnly ? 'active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name ASC',
    );
    return results.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getByBarcode(String barcode) async {
    final db = await _db.database;
    final results = await db.query(
      'products',
      where: 'barcode = ? AND active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<Product?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<List<Product>> search(String query) async {
    final db = await _db.database;
    final results = await db.query(
      'products',
      where: '(name LIKE ? OR barcode LIKE ?) AND active = 1',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return results.map((m) => Product.fromMap(m)).toList();
  }

  Future<void> insert(Product product) async {
    final db = await _db.database;
    await db.insert('products', product.toMap());
  }

  Future<void> update(Product product) async {
    final db = await _db.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    // Soft delete — set active = 0
    await db.update(
      'products',
      {'active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> decrementStock(String id, int quantity) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE products SET stock = MAX(0, stock - ?), updated_at = ? WHERE id = ?',
      [quantity, DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> restockProduct(String productId, int quantity) async {
    if (quantity <= 0) {
      throw ArgumentError('Restock quantity must be greater than zero');
    }

    final db = await _db.database;
    await db.transaction((txn) async {
      final results = await txn.query(
        'products',
        where: 'id = ? AND active = 1',
        whereArgs: [productId],
        limit: 1,
      );

      if (results.isEmpty) {
        throw StateError('Product not found');
      }

      final existing = Product.fromMap(results.first);
      final updated = existing.copyWith(stock: existing.stock + quantity);

      await txn.update(
        'products',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [productId],
      );
    });
  }

  Future<List<String>> getCategories() async {
    final db = await _db.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE active = 1 ORDER BY category',
    );
    return results.map((m) => m['category'] as String).toList();
  }
}
