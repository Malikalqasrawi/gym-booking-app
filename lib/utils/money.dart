/// Formats a JOD amount with up to 3 decimals (1 JOD = 1000 fils), dropping trailing zeros.
String formatJod(double amount) {
  var text = amount.toStringAsFixed(3);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return '$text JOD';
}
