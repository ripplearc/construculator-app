import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/search_filters/domain/entities/date_range.dart';
import 'package:construculator/libraries/search_filters/presentation/widgets/date_range_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart' hide DateRange;

/// A reusable filter chip for a search screen's modification-date filter.
///
/// Renders a plain chip that opens [DateRangeBottomSheet] when no range is
/// selected, or an active pill showing the selected range with a clear ×
/// when one is. The chip is surface-agnostic: each caller supplies its own
/// [label], accessibility labels, and widget [Key]s so the same widget can
/// back both global and project search without hardcoding either surface's
/// localization keys.
///
/// Callers that intend to widget-test the chip should supply both
/// [inactiveChipKey] and [activeChipKey]; without them the two chip variants
/// have no stable finder targets.
// TODO: [CA-796] Promote to CoreUI — the chip is domain-agnostic and any list
// screen with a date field could reuse it.
// https://ripplearc.youtrack.cloud/issue/CA-796
class DateFilterChip extends StatelessWidget {
  /// The currently selected date range, or `null` if no filter is active.
  final DateRange? selectedDateRange;

  /// Called with the newly chosen range when the user applies a selection.
  final ValueChanged<DateRange> onApply;

  /// Called when the user taps the × to clear the active filter.
  final VoidCallback onClear;

  /// Label shown on the chip when no range is selected.
  final String label;

  /// Accessibility label for the chip when no range is selected.
  final String semanticLabel;

  /// Accessibility label for the active pill that clears the filter on tap.
  final String clearSemanticLabel;

  /// Key applied to the inactive chip (no range selected).
  final Key? inactiveChipKey;

  /// Key applied to the active pill (a range is selected).
  final Key? activeChipKey;

  /// Creates a [DateFilterChip].
  const DateFilterChip({
    super.key,
    required this.selectedDateRange,
    required this.onApply,
    required this.onClear,
    required this.label,
    required this.semanticLabel,
    required this.clearSemanticLabel,
    this.inactiveChipKey,
    this.activeChipKey,
  });

  Future<void> _showSheet(BuildContext context) async {
    final range = await DateRangeBottomSheet.show(
      context: context,
      initialRange: selectedDateRange,
    );
    if (range != null) {
      onApply(range);
    }
  }

  String _formatRange(DateRange range) {
    final start = DisplayFormatter.formatDate(range.start);
    if (range.start == range.end) return start;
    final end = DisplayFormatter.formatDate(range.end);
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final range = selectedDateRange;

    if (range == null) {
      return Semantics(
        label: semanticLabel,
        child: CoreFilterChip(
          key: inactiveChipKey,
          label: label,
          onTap: () => _showSheet(context),
        ),
      );
    }

    return Semantics(
      label: clearSemanticLabel,
      button: true,
      child: InkWell(
        key: activeChipKey,
        onTap: onClear,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        child: Container(
          // Guarantee a 48dp-tall tap target to meet the Android/iOS minimum
          // tap-target accessibility guideline; the symmetric padding alone
          // leaves the pill shorter than 48dp.
          constraints: const BoxConstraints(minHeight: CoreSpacing.space12),
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space3,
            vertical: CoreSpacing.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CoreSpacing.space3),
            color: colors.backgroundGrayMid,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(
                  _formatRange(range),
                  style: typography.bodyMediumRegular.copyWith(
                    color: colors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: CoreSpacing.space2),
              ExcludeSemantics(
                child: CoreIconWidget(
                  icon: CoreIcons.close,
                  color: colors.iconDark,
                  size: CoreSpacing.space4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
