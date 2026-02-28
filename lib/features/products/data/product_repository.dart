import '../../../core/database/database_helper.dart';
import '../domain/product.dart';

class ProductRepository {
  final DatabaseHelper _db;

  ProductRepository(this._db);

  Future<List<Product>> getAll({bool activeOnly = true}) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        p.price,
        p.barcode,
        p.category,
        p.active,
        p.created_at,
        p.updated_at,
        COALESCE(SUM(
          CASE
            WHEN t.type = 'sale' THEN -t.quantity
            WHEN t.type IN ('restock', 'refund') THEN t.quantity
            ELSE 0
          END
        ), 0) AS stock
      FROM products p
      LEFT JOIN inventory_transactions t ON t.productId = p.id
      ${activeOnly ? 'WHERE p.active = 1' : ''}
      GROUP BY p.id
      ORDER BY p.name ASC
      ''',
    );
    return results.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getByBarcode(String barcode) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        p.price,
        p.barcode,
        p.category,
        p.active,
        p.created_at,
        p.updated_at,
        COALESCE(SUM(
          CASE
            WHEN t.type = 'sale' THEN -t.quantity
            WHEN t.type IN ('restock', 'refund') THEN t.quantity
            ELSE 0
          END
        ), 0) AS stock
      FROM products p
      LEFT JOIN inventory_transactions t ON t.productId = p.id
      WHERE p.barcode = ? AND p.active = 1
      GROUP BY p.id
      LIMIT 1
      ''',
      [barcode],
    );
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<Product?> getById(String id) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        p.price,
        p.barcode,
        p.category,
        p.active,
        p.created_at,
        p.updated_at,
        COALESCE(SUM(
          CASE
            WHEN t.type = 'sale' THEN -t.quantity
            WHEN t.type IN ('restock', 'refund') THEN t.quantity
            ELSE 0
          END
        ), 0) AS stock
      FROM products p
      LEFT JOIN inventory_transactions t ON t.productId = p.id
      WHERE p.id = ?
      GROUP BY p.id
      LIMIT 1
      ''',
      [id],
    );
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<List<Product>> search(String query) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        p.price,
        p.barcode,
        p.category,
        p.active,
        p.created_at,
        p.updated_at,
        COALESCE(SUM(
          CASE
            WHEN t.type = 'sale' THEN -t.quantity
            WHEN t.type IN ('restock', 'refund') THEN t.quantity
            ELSE 0
          END
        ), 0) AS stock
      FROM products p
      LEFT JOIN inventory_transactions t ON t.productId = p.id
      WHERE (p.name LIKE ? OR p.barcode LIKE ?) AND p.active = 1
      GROUP BY p.id
      ORDER BY p.name ASC
      ''',
      ['%$query%', '%$query%'],
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

  Future<List<String>> getCategories() async {
    final db = await _db.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE active = 1 ORDER BY category',
    );
    return results.map((m) => m['category'] as String).toList();
  }
}
