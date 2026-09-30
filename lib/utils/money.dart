/// Prices are in Jordanian dinars (JOD). 1 JOD = 1000 fils, so up to 3 decimals.
///
///   20.0   → "20 JOD"
///   13.5   → "13.5 JOD"
///   12.345 → "12.345 JOD"
String formatJod(double amount) {
  var text = amount.toStringAsFixed(3); // "13.500"
  text = text.replaceFirst(RegExp(r'0+$'), ''); // "13.5"
  text = text.replaceFirst(RegExp(r'\.$'), ''); // "20." → "20"
  return '$text JOD';
}
