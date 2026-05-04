import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The estimation feature's concrete tile widget.
///
/// Feature-owned and exposed to other features only through
/// [EstimationTileProvider], so consumers depend on the contract rather than
/// this implementation. Purely presentational — all data flows in via
/// [EstimationTileData].
///
/// Accessibility: the card is wrapped in [Semantics] with `button: true` and
/// the estimate name as the label. The menu button gets its own labeled
/// semantics node when [onMenuTap] is provided, and is hidden from the a11y
/// tree via [ExcludeSemantics] when null.
class SharedEstimationTile extends StatelessWidget {
  final EstimationTileData data;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;

  const SharedEstimationTile({
    super.key,
    required this.data,
    required this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.colorTheme;
    return Semantics(
      button: true,
      label: data.estimateName,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: CoreSpacing.space3),
        decoration: BoxDecoration(
          color: appColors.pageBackground,
          borderRadius: BorderRadius.circular(CoreSpacing.space3),
          boxShadow: CoreShadows.small,
        ),
        padding: const EdgeInsets.all(CoreSpacing.space4),
        child: GestureDetector(
          key: const Key('tileGestureDetector'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopRow(context),
              const SizedBox(height: CoreSpacing.space3),
              _buildMiddleRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    return Row(
      children: [
        CoreIconWidget(
          key: const Key('moneyIcon'),
          icon: CoreIcons.cost,
          color: appColors.iconGrayMid,
          size: 24,
        ),
        const SizedBox(width: CoreSpacing.space3),
        Expanded(
          child: Text(
            data.estimateName,
            style: typography.bodyLargeMedium.copyWith(
              color: appColors.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildMenuButton(context),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final appColors = context.colorTheme;

    final hitTarget = SizedBox(
      width: CoreSpacing.space12,
      height: CoreSpacing.space12,
      child: GestureDetector(
        onTap: onMenuTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: CoreIconWidget(
            key: const Key('menuIcon'),
            icon: CoreIcons.moreVert,
            color: appColors.iconDark,
            size: 24,
          ),
        ),
      ),
    );

    if (onMenuTap != null) {
      return Semantics(
        button: true,
        label: context.l10n.estimationMenuLabel(data.estimateName),
        child: hitTarget,
      );
    }

    return ExcludeSemantics(child: hitTarget);
  }

  Widget _buildMiddleRow(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return Row(
      children: [
        CoreIconWidget(
          key: const Key('calendarIcon'),
          icon: CoreIcons.calendar,
          color: appColors.iconGrayMid,
          size: 14,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          DisplayFormatter.formatDate(data.displayDate),
          style: typography.bodySmallRegular,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Container(
          width: CoreSpacing.space1,
          height: CoreSpacing.space1,
          decoration: BoxDecoration(
            color: appColors.lineDarkOutline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          DisplayFormatter.formatTime(data.displayDate),
          style: typography.bodySmallRegular,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Expanded(
          child: Text(
            textAlign: TextAlign.right,
            DisplayFormatter.formatCurrency(data.totalCost),
            style: typography.bodyLargeSemiBold.copyWith(
              color: appColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
