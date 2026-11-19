import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One number field being typed into from the app's own number pad.
///
/// The pad's keys never reach the platform text input, so the field's
/// [TextInputFormatter] and its `onChanged` do not run for them. The session
/// edits the [controller] at its selection the way a typed key would, runs
/// [formatter] over the edit, and reports every change to the text through
/// [onChanged], so the form's bloc hears the pad exactly as it hears the
/// phone's keyboard.
///
/// A field whose selection is not set, for example after its text was
/// assigned, is edited at the end of its text.
class NumberPadSession {
  /// The controller of the field the pad types into.
  final TextEditingController controller;

  /// The field's own formatter, applied to every edit the pad makes.
  final TextInputFormatter formatter;

  /// Called with the field's new text after every edit that changes it, and
  /// after [putBack].
  final ValueChanged<String> onChanged;

  /// The text the field held when the pad opened.
  final String openedWith;

  /// The put-back button's label, fixed when the pad opened: what
  /// [putBackLabelOf] made of [openedWith], such as "Back to 25" or "Clear".
  final String putBackLabel;

  /// [putBackLabelOf] names the put-back button for the text the field holds
  /// now, which becomes [openedWith].
  NumberPadSession({
    required this.controller,
    required this.formatter,
    required this.onChanged,
    required String Function(String openedWith) putBackLabelOf,
  }) : openedWith = controller.text,
       putBackLabel = putBackLabelOf(controller.text);

  /// Replaces the selection with [digit], 0 to 9.
  void typeDigit(int digit) {
    assert(digit >= 0 && digit <= 9, 'A digit key sends 0 to 9, not $digit');
    _replaceSelection('$digit');
  }

  /// Replaces the selection with a decimal point.
  void typeDecimal() => _replaceSelection('.');

  /// Deletes the selection, or the character before the caret.
  void backspace() {
    final value = controller.value;
    final selection = _selectionOf(value);
    if (!selection.isCollapsed) {
      _replace(value, selection, '');
    } else if (selection.start > 0) {
      final range = TextRange(start: selection.start - 1, end: selection.start);
      _replace(value, range, '');
    }
  }

  /// Puts [openedWith] back into the field, with the caret after it.
  void putBack() {
    controller.value = TextEditingValue(
      text: openedWith,
      selection: TextSelection.collapsed(offset: openedWith.length),
    );
    onChanged(openedWith);
  }

  void _replaceSelection(String text) {
    final value = controller.value;
    _replace(value, _selectionOf(value), text);
  }

  TextSelection _selectionOf(TextEditingValue value) => value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);

  void _replace(TextEditingValue previous, TextRange range, String text) {
    // Not TextEditingValue.replaced: it keeps a same-length selection, so a
    // digit typed over a selected digit would stay selected and the next key
    // would replace it too. The caret always lands after what was typed.
    final next = TextEditingValue(
      text: previous.text.replaceRange(range.start, range.end, text),
      selection: TextSelection.collapsed(offset: range.start + text.length),
    );
    final formatted = formatter.formatEditUpdate(previous, next);
    controller.value = formatted;
    if (formatted.text != previous.text) onChanged(formatted.text);
  }
}
