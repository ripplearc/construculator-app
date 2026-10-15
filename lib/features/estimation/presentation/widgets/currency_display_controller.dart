import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/widgets.dart';

/// A [TextEditingController] whose text stays a plain number such as `400`,
/// but which paints it as currency (`$400.00`) while [focusNode] is not
/// focused.
///
/// Because only the painted text changes, listeners and `double.tryParse` on
/// [text] keep working, and the user edits the raw number once the field
/// takes focus. Text that is not a number is painted as typed.
class CurrencyDisplayController extends TextEditingController {
  final FocusNode focusNode;

  CurrencyDisplayController({required this.focusNode}) {
    focusNode.addListener(notifyListeners);
  }

  @override
  void dispose() {
    focusNode.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final amount = double.tryParse(text);
    if (focusNode.hasFocus || amount == null) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return TextSpan(
      style: style,
      text: DisplayFormatter.currency.format(amount),
    );
  }
}
