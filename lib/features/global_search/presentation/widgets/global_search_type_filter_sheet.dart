import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A modal bottom sheet for choosing the search scope (Type filter) on the
/// global search screen, matching the "Select Filter by cost or calculation"
/// design.
///
/// Shows the Cost and Calculation options with the currently active one
/// marked. Selection is kept local until the user taps Apply, which invokes
/// [onApply] with the chosen scope — [SearchScope.estimation] when Cost is
/// selected, [SearchScope.dashboard] (no Type filter) when nothing is —
/// and dismisses the sheet. Tapping Clear all deselects without dismissing.
///
/// The Calculation option is disabled: the global_search RPC rejects the
/// calculation scope (SQLSTATE 22023, found during the CA-838 E2E pass), so
/// it cannot be offered until backend support lands.
class GlobalSearchTypeFilterSheet extends StatefulWidget {
  /// The scope that is active when the sheet opens.
  final SearchScope selectedScope;

  /// Called with the chosen scope when the user taps Apply.
  final void Function(SearchScope) onApply;

  /// Creates a [GlobalSearchTypeFilterSheet].
  const GlobalSearchTypeFilterSheet({
    super.key,
    required this.selectedScope,
    required this.onApply,
  });

  @override
  State<GlobalSearchTypeFilterSheet> createState() =>
      _GlobalSearchTypeFilterSheetState();
}

class _GlobalSearchTypeFilterSheetState
    extends State<GlobalSearchTypeFilterSheet> {
  late bool _costSelected = widget.selectedScope == SearchScope.estimation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space4,
            vertical: CoreSpacing.space3,
          ),
          child: Text(
            l10n.globalSearchTypeSheetTitle,
            style: typography.titleLargeSemiBold.copyWith(
              color: colors.textHeadline,
            ),
          ),
        ),
        const SizedBox(height: CoreSpacing.space4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypeOptionRow(
                key: const Key('type_filter_option_cost'),
                label: l10n.globalSearchTypeCostLabel,
                isSelected: _costSelected,
                onTap: () => setState(() => _costSelected = !_costSelected),
              ),
              _TypeOptionRow(
                key: const Key('type_filter_option_calculation'),
                label: l10n.globalSearchTypeCalculationLabel,
                isSelected: false,
                enabled: false,
                onTap: null,
              ),
            ],
          ),
        ),
        Padding(
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
                  key: const Key('type_filter_clear_all_button'),
                  label: l10n.globalSearchTypeSheetClearAll,
                  variant: CoreButtonVariant.secondary,
                  onPressed: () => setState(() => _costSelected = false),
                ),
              ),
              const SizedBox(width: CoreSpacing.space3),
              Expanded(
                child: CoreButton(
                  key: const Key('type_filter_apply_button'),
                  label: l10n.globalSearchTypeSheetApply,
                  onPressed: () {
                    widget.onApply(
                      _costSelected
                          ? SearchScope.estimation
                          : SearchScope.dashboard,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeOptionRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _TypeOptionRow({
    super.key,
    required this.label,
    required this.isSelected,
    this.enabled = true,
    required this.onTap,
  });

  // Pill radius for the selected row, matching the 48px cornerRadius the
  // sibling sort sheet uses on a 48px tall cell.
  static const double _selectedRadius = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final radius = BorderRadius.circular(
      isSelected ? _selectedRadius : CoreSpacing.space2,
    );

    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: isSelected,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(CoreSpacing.space3),
          decoration: BoxDecoration(
            color: isSelected ? colors.orientLight : null,
            borderRadius: radius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: typography.bodyMediumRegular.copyWith(
                  color: enabled ? colors.textDark : colors.textDisable,
                ),
              ),
              if (isSelected)
                CoreIconWidget(
                  icon: CoreIcons.checkMark,
                  size: CoreIconSize.size24,
                  color: colors.statusSuccess,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
