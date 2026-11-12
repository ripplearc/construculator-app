import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The bar fixed at the bottom of the estimate screen: the estimate total with
/// its small `Total` label above it, then `+ Add cost` and `Preview` side by
/// side.
///
/// `+ Add cost` is always here unless the estimate is known to be empty, and
/// never sits inside a section. While the estimate is empty the bar holds only the total
/// and a greyed-out Preview, because `Add the first cost` in the list is the
/// one way in. Preview stays visible and is greyed out while [onPreview] is
/// null.
class AddCostBottomBar extends StatelessWidget {
  /// Key of the `+ Add cost` button.
  static const addCostButtonKey = Key('add_cost_button');

  /// Key of the Preview button.
  static const previewButtonKey = Key('preview_button');

  /// Key of the estimate total amount.
  static const totalKey = Key('estimate_total_amount');

  static const double _emptyPreviewWidth = 120;

  /// The estimate total, in dollars. A null total shows a dash, so a total
  /// that has not loaded never reads as $0.00.
  final double? total;

  /// Whether the estimate is known to hold no cost. When true the bar leaves
  /// out `+ Add cost`. It stays false while the costs are still loading.
  final bool isEstimateEmpty;

  /// Called when the user taps `+ Add cost`.
  final VoidCallback onAddCost;

  /// Called when the user taps Preview. Null greys the button out.
  final VoidCallback? onPreview;

  const AddCostBottomBar({
    super.key,
    required this.total,
    required this.isEstimateEmpty,
    required this.onAddCost,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final totalBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.estimateTotalLabel,
          style: textTheme.bodyMediumRegular.copyWith(
            color: colorTheme.textBody,
          ),
        ),
        Text(
          DisplayFormatter.formatCurrency(total),
          key: totalKey,
          style: textTheme.headlineMediumSemiBold.copyWith(
            color: colorTheme.textHeadline,
          ),
        ),
      ],
    );
    final preview = CoreButton(
      key: previewButtonKey,
      label: l10n.previewButton,
      onPressed: onPreview,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: CoreShadows.sticky,
        color: sheetSurface(context),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CoreSpacing.space4),
          child: !isEstimateEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CoreSpacing.space3,
                  children: [
                    totalBlock,
                    Row(
                      spacing: CoreSpacing.space4,
                      children: [
                        Expanded(
                          child: CoreButton(
                            key: addCostButtonKey,
                            label: l10n.addCostButton,
                            variant: CoreButtonVariant.secondary,
                            icon: CoreIconWidget(
                              icon: CoreIcons.add,
                              color: colorTheme.buttonSurface,
                            ),
                            onPressed: onAddCost,
                          ),
                        ),
                        Expanded(child: preview),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: totalBlock),
                    SizedBox(
                      width: _emptyPreviewWidth,
                      height: CoreSpacing.space12,
                      child: preview,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
