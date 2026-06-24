import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('\$') {
    _loadCurrency();
  }

  static const _key = 'selected_currency';

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? '\$';
  }

  Future<void> setCurrency(String symbol) async {
    state = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, symbol);
  }
}

final supportedCurrencies = ['\$', '€', '£', '₹', '¥', '₽', '₩', 'A\$', 'C\$', 'CHF', 'kr', 'R\$', '₺', 'Rp', 'RM', '₱', '฿', '₫', '₪'];
final currencyNames = {
  '\$': 'US Dollar',
  '€': 'Euro',
  '£': 'British Pound',
  '₹': 'Indian Rupee',
  '¥': 'Japanese Yen',
  '₽': 'Russian Ruble',
  '₩': 'Korean Won',
  'A\$': 'Australian Dollar',
  'C\$': 'Canadian Dollar',
  'CHF': 'Swiss Franc',
  'kr': 'Swedish Krona',
  'R\$': 'Brazilian Real',
  '₺': 'Turkish Lira',
  'Rp': 'Indonesian Rupiah',
  'RM': 'Malaysian Ringgit',
  '₱': 'Philippine Peso',
  '฿': 'Thai Baht',
  '₫': 'Vietnamese Dong',
  '₪': 'Israeli Shekel',
};

final currencyFlags = {
  '\$': 'us',
  '€': 'eu',
  '£': 'gb',
  '₹': 'in',
  '¥': 'jp',
  '₽': 'ru',
  '₩': 'kr',
  'A\$': 'au',
  'C\$': 'ca',
  'CHF': 'ch',
  'kr': 'se',
  'R\$': 'br',
  '₺': 'tr',
  'Rp': 'id',
  'RM': 'my',
  '₱': 'ph',
  '฿': 'th',
  '₫': 'vn',
  '₪': 'il',
};
