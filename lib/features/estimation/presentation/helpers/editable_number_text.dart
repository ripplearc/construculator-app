/// A number as the user would type it: `52` for a whole number, `9.5`
/// otherwise, never `52.0`. Used to put a saved rate back into a text field.
String editableNumberText(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
