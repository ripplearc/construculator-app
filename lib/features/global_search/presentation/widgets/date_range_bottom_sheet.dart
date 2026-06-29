import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// An inclusive date range, truncated to whole calendar days.
class DateRange {
  /// The first day included in the range.
  final DateTime start;

  /// The last day included in the range.
  final DateTime end;

  /// Creates a [DateRange] spanning [start] to [end], inclusive.
  const DateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

enum _PredefinedRange { today, last7Days, last30Days, thisMonth, custom }

/// A modal bottom sheet for picking a date range to filter search results.
///
/// Offers predefined ranges (today, last 7/30 days, this month) plus a
/// Custom range option that opens [CoreDatePicker] twice — once for the
/// start date, once for the end date — since [CoreDatePicker] only selects a
/// single date. The sheet owns no BLoC state: it resolves with the chosen
/// [DateRange], or `null` if the user cancels/dismisses.
class DateRangeBottomSheet extends StatefulWidget {
  /// The range already applied when the sheet opens, if any.
  final DateRange? initialRange;

  /// Creates a [DateRangeBottomSheet].
  const DateRangeBottomSheet({super.key, this.initialRange});

  /// Shows [DateRangeBottomSheet] inside a [CoreQuickSheet] and resolves with
  /// the chosen [DateRange], or `null` if the user cancels/dismisses.
  static Future<DateRange?> show({
    required BuildContext context,
    DateRange? initialRange,
  }) {
    return CoreQuickSheet.show<DateRange?>(
      context: context,
      child: DateRangeBottomSheet(initialRange: initialRange),
    );
  }

  @override
  State<DateRangeBottomSheet> createState() => _DateRangeBottomSheetState();
}

class _DateRangeBottomSheetState extends State<DateRangeBottomSheet> {
  late _PredefinedRange _selected;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _customStart = widget.initialRange?.start;
    _customEnd = widget.initialRange?.end;
    _selected = widget.initialRange == null
        ? _PredefinedRange.today
        : _PredefinedRange.custom;
  }

  DateRange _rangeFor(_PredefinedRange range, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (range) {
      case _PredefinedRange.today:
        return DateRange(start: today, end: today);
      case _PredefinedRange.last7Days:
        return DateRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _PredefinedRange.last30Days:
        return DateRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case _PredefinedRange.thisMonth:
        return DateRange(
          start: DateTime(today.year, today.month, 1),
          end: today,
        );
      case _PredefinedRange.custom:
        return DateRange(
          start: _customStart ?? today,
          end: _customEnd ?? today,
        );
    }
  }

  Future<void> _pickCustomRange(AppLocalizations l10n) async {
    final now = DateTime.now();
    final start = await CoreDatePicker.show(
      context: context,
      initialDate: _customStart ?? now,
      lastDate: now,
      label: l10n.dateRangeSheetStartDateLabel,
    );
    if (start == null || !mounted) return;

    final end = await CoreDatePicker.show(
      context: context,
      initialDate: _customEnd ?? start,
      firstDate: start,
      lastDate: now,
      label: l10n.dateRangeSheetEndDateLabel,
    );
    if (end == null || !mounted) return;

    setState(() {
      _selected = _PredefinedRange.custom;
      _customStart = start;
      _customEnd = end;
    });
  }

  void _onApply() {
    // [_selected] is only ever set to custom once both custom dates have been
    // picked (see [_pickCustomRange]); cancelling a picker reverts the
    // selection to its prior value. So the custom branch of [_rangeFor] can
    // never resolve to its today→today fallback at apply time — no extra guard
    // is needed here.
    Navigator.of(context).pop(_rangeFor(_selected, DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(typography, l10n),
        _buildRangeOptions(typography, l10n),
        _buildActionButtons(l10n),
      ],
    );
  }

  Widget _buildTitle(AppTypographyExtension typography, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space3,
      ),
      child: Text(
        l10n.dateRangeSheetTitle,
        style: typography.bodyLargeSemiBold,
      ),
    );
  }

  Widget _buildRangeOptions(
    AppTypographyExtension typography,
    AppLocalizations l10n,
  ) {
    final options = <_PredefinedRange, String>{
      _PredefinedRange.today: l10n.dateRangeSheetToday,
      _PredefinedRange.last7Days: l10n.dateRangeSheetLast7Days,
      _PredefinedRange.last30Days: l10n.dateRangeSheetLast30Days,
      _PredefinedRange.thisMonth: l10n.dateRangeSheetThisMonth,
      _PredefinedRange.custom: l10n.dateRangeSheetCustomRange,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.entries.map((entry) {
        final range = entry.key;
        return RadioListTile<_PredefinedRange>(
          key: Key('date_range_option_${range.name}'),
          value: range,
          groupValue: _selected,
          title: Text(entry.value, style: typography.bodyLargeRegular),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (_) {
            if (range == _PredefinedRange.custom) {
              // Only reopen the pickers when there is no complete custom range
              // yet, or the user is switching back to Custom from another
              // option. Re-tapping an already-complete Custom selection just
              // keeps it instead of forcing the pickers open again.
              if (_customStart == null ||
                  _customEnd == null ||
                  _selected != _PredefinedRange.custom) {
                _pickCustomRange(l10n);
              } else {
                setState(() => _selected = _PredefinedRange.custom);
              }
            } else {
              setState(() => _selected = range);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CoreSpacing.space4,
        CoreSpacing.space3,
        CoreSpacing.space4,
        CoreSpacing.space4,
      ),
      child: Row(
        children: [
          Expanded(
            child: CoreButton(
              key: const Key('date_range_cancel_button'),
              label: l10n.dateRangeSheetCancel,
              variant: CoreButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: CoreSpacing.space3),
          Expanded(
            child: CoreButton(
              key: const Key('date_range_apply_button'),
              label: l10n.dateRangeSheetApply,
              onPressed: _onApply,
            ),
          ),
        ],
      ),
    );
  }
}
