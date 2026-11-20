import 'package:construculator/l10n/generated/app_localizations.dart';

/// The label of the number pad's put-back button for [openedWith], the text
/// a field held when the pad opened: "Clear" for an empty field, otherwise
/// "Back to" and the value as [shown], for example "Back to 25" or
/// "Back to $52". [shown] adds the field's sign and defaults to the bare text.
String numberPadPutBackLabel(
  AppLocalizations l10n,
  String openedWith, {
  String Function(String value)? shown,
}) {
  if (openedWith.isEmpty) return l10n.numberPadClearButton;
  return l10n.numberPadPutBackButton(shown?.call(openedWith) ?? openedWith);
}
