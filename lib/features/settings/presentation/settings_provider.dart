import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(DatabaseHelper.instance);
});

/// Settings map — loaded once, updated on save.
final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, String>>((ref) {
  return SettingsNotifier(ref.read(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<Map<String, String>> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super({});

  Future<void> load() async {
    state = await _repo.getAll();
  }

  Future<void> update(String key, String value) async {
    await _repo.set(key, value);
    state = {...state, key: value};
  }

  Future<void> updateAll(Map<String, String> updates) async {
    await _repo.setAll(updates);
    state = {...state, ...updates};
  }

  double get taxPercent => double.tryParse(state['tax_percent'] ?? '') ?? 8.0;
  String get currency => state['currency'] ?? 'USD';
  String get receiptFooter => state['receipt_footer'] ?? 'Thank you for your purchase!';
  bool get simulateFailures => state['simulate_payment_failures'] == 'true';
}
