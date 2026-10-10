import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/widgets.dart';

/// The line under the equipment name on the compact saved-rate screen, such as
/// `$120.00 /day · your default`. Both the sheet header and the form body
/// build it here, from the saved [rate] and its pricing [method].
String recalledRateSubtitle(
  BuildContext context, {
  required double rate,
  required EquipmentPricingMethod method,
}) {
  final l10n = context.l10n;
  return l10n.equipmentRecalledRateSubtitle(
    DisplayFormatter.currency.format(rate),
    method == EquipmentPricingMethod.day
        ? l10n.yourRatesDaySuffix
        : l10n.yourRatesJobSuffix,
  );
}
