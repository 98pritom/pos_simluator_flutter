import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Central database helper — single instance, versioned migrations.
/// sqflite chosen over isar for: SQL familiarity in POS domain,
/// mature ecosystem, proven offline reliability, simpler debugging.
class DatabaseHelper {
  static Database? _database;
  static const _dbName = 'pos_simulator.db';
  static const _dbVersion = 1;

  DatabaseHelper._();
  static final instance = DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        pin TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'cashier'
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        barcode TEXT UNIQUE,
        category TEXT NOT NULL DEFAULT 'General',
        stock INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax_amount REAL NOT NULL,
        discount_amount REAL NOT NULL,
        grand_total REAL NOT NULL,
        payment_type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Indexes for common queries
    await db.execute(
      'CREATE INDEX idx_products_barcode ON products(barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_orders_created ON orders(created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_order_items_order ON order_items(order_id)',
    );

    // Seed default data
    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  Future<void> _seedDefaults(Database db) async {
    // Default users
    await db.insert('users', {
      'id': 'admin-001',
      'name': 'Admin',
      'pin': '1234',
      'role': 'admin',
    });
    await db.insert('users', {
      'id': 'cashier-001',
      'name': 'Cashier 1',
      'pin': '0000',
      'role': 'cashier',
    });

    // Default settings
    final defaults = {
      'tax_percent': '8.0',
      'currency': 'USD',
      'receipt_footer': 'Thank you for your purchase!',
      'simulate_payment_failures': 'false',
    };
    for (final entry in defaults.entries) {
      await db.insert('settings', {'key': entry.key, 'value': entry.value});
    }

    // Dummy products
    final now = DateTime.now().toIso8601String();
    final products = [
      {'id': 'prod-001', 'name': 'Espresso', 'price': 3.50, 'barcode': '1000000001', 'category': 'Beverages', 'stock': 100},
      {'id': 'prod-002', 'name': 'Cappuccino', 'price': 4.50, 'barcode': '1000000002', 'category': 'Beverages', 'stock': 80},
      {'id': 'prod-003', 'name': 'Latte', 'price': 5.00, 'barcode': '1000000003', 'category': 'Beverages', 'stock': 75},
      {'id': 'prod-004', 'name': 'Green Tea', 'price': 3.00, 'barcode': '1000000004', 'category': 'Beverages', 'stock': 60},
      {'id': 'prod-005', 'name': 'Croissant', 'price': 2.50, 'barcode': '1000000005', 'category': 'Bakery', 'stock': 40},
      {'id': 'prod-006', 'name': 'Muffin', 'price': 3.00, 'barcode': '1000000006', 'category': 'Bakery', 'stock': 35},
      {'id': 'prod-007', 'name': 'Bagel', 'price': 2.00, 'barcode': '1000000007', 'category': 'Bakery', 'stock': 50},
      {'id': 'prod-008', 'name': 'Sandwich', 'price': 6.50, 'barcode': '1000000008', 'category': 'Food', 'stock': 25},
      {'id': 'prod-009', 'name': 'Salad Bowl', 'price': 7.00, 'barcode': '1000000009', 'category': 'Food', 'stock': 20},
      {'id': 'prod-010', 'name': 'Cookie', 'price': 1.50, 'barcode': '1000000010', 'category': 'Snacks', 'stock': 100},
      {'id': 'prod-011', 'name': 'Brownie', 'price': 2.50, 'barcode': '1000000011', 'category': 'Snacks', 'stock': 60},
      {'id': 'prod-012', 'name': 'Water Bottle', 'price': 1.00, 'barcode': '1000000012', 'category': 'Beverages', 'stock': 200},
    ];
    for (final p in products) {
      await db.insert('products', {
        ...p,
        'active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
