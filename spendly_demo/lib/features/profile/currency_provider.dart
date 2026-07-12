import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'selected_currency';

  CurrencyNotifier() : super('₺') {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final cur = await _storage.read(key: _key);
    if (cur != null) {
      state = cur;
    }
  }

  Future<void> setCurrency(String newCurrency) async {
    state = newCurrency;
    await _storage.write(key: _key, value: newCurrency);
  }

  static Future<void> clearPersistedCurrency() async {
    await _storage.delete(key: _key);
  }
}
