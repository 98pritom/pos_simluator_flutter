import '../../../core/database/database_helper.dart';
import '../domain/user.dart';

class AuthRepository {
  final DatabaseHelper _db;

  AuthRepository(this._db);

  Future<User?> authenticateByPin(String pin) async {
    final db = await _db.database;
    final results = await db.query(
      'users',
      where: 'pin = ?',
      whereArgs: [pin],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<List<User>> getAllUsers() async {
    final db = await _db.database;
    final results = await db.query('users');
    return results.map((m) => User.fromMap(m)).toList();
  }
}
