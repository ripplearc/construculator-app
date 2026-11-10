/// Shows [value] for a text field: no decimals when it is a whole number,
/// otherwise as many as it has.
String formatTrimmedNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
