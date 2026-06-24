import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {
    String symbol = '₹', 
    bool showSymbol = true,
    bool compact = false,
  }) {
    if (compact) {
      return '${showSymbol ? symbol : ''}${_formatCompact(amount)}';
    }

    int decimals = amount.toStringAsFixed(2).endsWith('.00') ? 0 : 2;

    // Indian Numbering System: 1,00,000
    // intl doesn't fully support "en_IN" custom patterns perfectly in all versions, 
    // but NumberFormat.currency(locale: 'en_IN') usually works.
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: showSymbol ? symbol : '',
      decimalDigits: decimals,
    );
    
    // Manual trim if needed or just use standard
    String formatted = format.format(amount).trim();
    if (!showSymbol) formatted = formatted.replaceAll(symbol, '').trim();
    return formatted;
  }

  static String _formatCompact(double number) {
    if (number.abs() < 1000) return number.toStringAsFixed(0);
    
    // Indian Suffixes: K, L (Lac), Cr (Crore)
    // 1 K = 1,000
    // 1 L = 1,00,000 (100 K)
    // 1 Cr = 1,00,00,000 (100 L)

    double val = number.abs();
    String sign = number < 0 ? '-' : '';
    
    if (val >= 10000000) {
      double cr = val / 10000000;
      return '$sign${cr.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}Cr';
    } else if (val >= 100000) {
      double l = val / 100000;
      return '$sign${l.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}L';
    } else if (val >= 1000) {
      double k = val / 1000;
      return '$sign${k.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    }
    
    return number.toStringAsFixed(0);
  }
}
