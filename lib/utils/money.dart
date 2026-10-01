/// Formats a JOD amount with up to 3 decimals (1 JOD = 1000 fils), dropping trailing zeros.
String formatJod(double amount) {
  var text = amount.toStringAsFixed(3);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return '$text JOD';
}

/// Formats an amount in [currency]: JOD as in [formatJod], other currencies with 2 decimals.
String formatMoney(double amount, String currency) {
  final code = currency.toUpperCase();
  if (code == 'JOD') return formatJod(amount);
  return '${amount.toStringAsFixed(2)} $code';
}
