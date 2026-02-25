import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

class SettingsRepository {
  final DatabaseHelper _db;

  SettingsRepository(this._db);

  Future<Map<String, String>> getAll() async {
    final db = await _db.database;
    final results = await db.query('settings');
    return {for (final row in results) row['key'] as String: row['value'] as String};
  }

  Future<String?> get(String key) async {
    final db = await _db.database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  Future<void> set(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setAll(Map<String, String> settings) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final entry in settings.entries) {
        await txn.insert(
          'settings',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
