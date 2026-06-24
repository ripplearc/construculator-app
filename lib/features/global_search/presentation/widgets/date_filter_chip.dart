import 'package:construculator/features/global_search/presentation/widgets/date_range_bottom_sheet.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Filter chip for the global search screen's modification-date filter.
///
/// Renders a plain chip that opens [DateRangeBottomSheet] when no range is
/// selected, or an active pill showing the selected range with a clear ×
/// when one is.
class DateFilterChip extends StatelessWidget {
  /// The currently selected date range, or `null` if no filter is active.
  final DateRange? selectedDateRange;

  /// Called with the newly chosen range when the user applies a selection.
  final ValueChanged<DateRange> onApply;

  /// Called when the user taps the × to clear the active filter.
  final VoidCallback onClear;

  const DateFilterChip({
    super.key,
    required this.selectedDateRange,
    required this.onApply,
    required this.onClear,
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
    final l10n = context.l10n;
    final range = selectedDateRange;

    if (range == null) {
      return Semantics(
        label: l10n.globalSearchFilterModifiedSemanticLabel,
        child: CoreFilterChip(
          key: const Key('global_search_date_filter_chip'),
          label: l10n.globalSearchFilterModified,
          onTap: () => _showSheet(context),
        ),
      );
    }

    return Semantics(
      label: l10n.globalSearchClearDateFilterSemanticLabel,
      button: true,
      child: InkWell(
        key: const Key('active_date_filter_chip'),
        onTap: onClear,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        child: Container(
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
