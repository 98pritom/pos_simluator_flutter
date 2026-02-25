import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

/// Auth state — null means not logged in.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(DatabaseHelper.instance);
});

final currentUserProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(null);

  Future<bool> login(String pin) async {
    final user = await _repo.authenticateByPin(pin);
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  void logout() {
    state = null;
  }
}
