class CurrencyFormatter {
  CurrencyFormatter._();

  static String defaultSymbol = 'रु ';

  static String format(num amount, {String? symbol}) {
    final activeSymbol = symbol ?? defaultSymbol;
    // Format Nepali numbering style: e.g. 2,48,500
    final isNegative = amount < 0;
    final absAmount = amount.abs().round();
    final str = absAmount.toString();
    if (str.length <= 3) {
      return '${isNegative ? '-' : ''}$activeSymbol$str';
    }

    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);

    final buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);

    return '${isNegative ? '-' : ''}$activeSymbol$buffer';
  }

  static String formatShort(num amount, {String? symbol}) {
    final activeSymbol = symbol ?? defaultSymbol;
    if (amount >= 10000000) {
      return '$activeSymbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '$activeSymbol${(amount / 100000).toStringAsFixed(amount % 100000 == 0 ? 0 : 2)}L';
    } else if (amount >= 1000) {
      return '$activeSymbol${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return '$activeSymbol$amount';
  }

  static String formatCompact(num amount, {String? symbol}) => formatShort(amount, symbol: symbol);
}
