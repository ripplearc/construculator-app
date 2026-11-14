import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:intl/intl.dart';

/// The meta row under a cost line's name: a bold [lead] and a regular [tail].
///
/// [tail] starts with its own separator, so [text] is the two joined.
class CostLineMeta {
  /// The bold first part, for example `13.25 sheets`.
  final String lead;

  /// The regular second part with its separator, for example ` · $14.50/sheet`.
  /// Empty when the row has no second part.
  final String tail;

  const CostLineMeta({required this.lead, this.tail = ''});

  /// The whole row as plain text.
  String get text => '$lead$tail';
}

/// Writes the meta row under a cost line's name on the estimate screen, for
/// example `4 days · $145.00/day + $85.00 delivery` for an equipment line.
///
/// A priced delivery fee goes on the meta row itself and never gets a line of
/// its own. [format] returns null when a line has nothing to show.
class CostLineMetaFormatter {
  CostLineMetaFormatter._();

  /// Key of the labor rate in `CostItem.calculation`.
  static const _laborRateKey = 'laborRate';

  /// The meta row of [item] in the language of [l10n].
  static CostLineMeta? format(CostItem item, AppLocalizations l10n) =>
      switch (item) {
        MaterialCostItem() => _materialMeta(item, l10n),
        LaborCostItem() => _laborMeta(item, l10n),
        EquipmentCostItem() => _equipmentMeta(item, l10n),
      };

  static NumberFormat _amount(AppLocalizations l10n) =>
      NumberFormat('#,##0.##', l10n.localeName);

  static CostLineMeta _materialMeta(
    MaterialCostItem item,
    AppLocalizations l10n,
  ) {
    final quantity = item.quantity;
    final unit = quantity.unit;
    return CostLineMeta(
      lead: l10n.costLineMaterialQuantity(
        _amount(l10n).format(quantity.value),
        unit.countName(l10n, quantity.value),
      ),
      tail: l10n.costLineMaterialRate(
        DisplayFormatter.formatCurrency(item.unitPrice.amount),
        unit.countName(l10n, 1),
      ),
    );
  }

  // TODO: [CA-1459] the burden line under a labor row needs a burden field on LaborCostItem.
  // https://ripplearc.youtrack.cloud/issue/CA-1459
  static CostLineMeta? _laborMeta(LaborCostItem item, AppLocalizations l10n) {
    final days = item.laborValue.laborDays;
    return switch (item.laborCalcMethod) {
      LaborCalculationMethodType.perHour
          when item.laborValue.laborHours != null =>
        CostLineMeta(
          lead: l10n.costLineLaborHoursMeta(
            _amount(l10n).format(item.laborValue.laborHours),
          ),
          tail: _laborRateTail(item, l10n, perHour: true),
        ),
      LaborCalculationMethodType.perDay when days != null => CostLineMeta(
        lead: l10n.costLineLaborDaysMeta(days),
        tail: _laborRateTail(item, l10n, perHour: false),
      ),
      _ => null,
    };
  }

  static String _laborRateTail(
    LaborCostItem item,
    AppLocalizations l10n, {
    required bool perHour,
  }) {
    final rate = item.calculation[_laborRateKey];
    if (rate == null) return '';
    final amount = DisplayFormatter.formatCurrency(rate);
    final crew = item.crewSize;
    if (crew != null && crew >= 2) {
      return perHour
          ? l10n.costLineLaborCrewHourRate(crew, amount)
          : l10n.costLineLaborCrewDayRate(crew, amount);
    }
    return perHour
        ? l10n.costLineLaborHourRate(amount)
        : l10n.costLineLaborDayRate(amount);
  }

  static CostLineMeta? _equipmentMeta(
    EquipmentCostItem item,
    AppLocalizations l10n,
  ) {
    final base = switch (item.pricingMethod) {
      EquipmentPricingMethod.day => _dayMeta(item, l10n),
      EquipmentPricingMethod.job => _jobMeta(item, l10n),
    };
    final fee = item.deliveryFee;
    if (base == null || fee == null) return base;
    return CostLineMeta(
      lead: base.lead,
      tail:
          base.tail +
          l10n.costLineDeliveryFee(DisplayFormatter.formatCurrency(fee.amount)),
    );
  }

  static CostLineMeta? _dayMeta(EquipmentCostItem item, AppLocalizations l10n) {
    final duration = item.duration;
    final rate = item.dailyRate;
    if (duration == null || rate == null) return null;
    return CostLineMeta(
      lead: l10n.costLineEquipmentDaysDuration(duration),
      tail: l10n.costLineEquipmentDayRate(
        DisplayFormatter.formatCurrency(rate.amount),
      ),
    );
  }

  static CostLineMeta? _jobMeta(EquipmentCostItem item, AppLocalizations l10n) {
    final job = item.jobAmount;
    if (job == null) return null;
    return CostLineMeta(
      lead: DisplayFormatter.formatCurrency(job.amount),
      tail: l10n.costLineEquipmentJobTail,
    );
  }
}
