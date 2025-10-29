import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';

class EstimationActionsSheetBody extends StatelessWidget {
  const EstimationActionsSheetBody({
    super.key,
    required this.estimationName,
    required this.onRename,
    required this.onFavourite,
    required this.onRemove,
    required this.isFavourite,
  });

  final String estimationName;
  final VoidCallback? onRename;
  final VoidCallback? onFavourite;
  final VoidCallback? onRemove;
  final bool isFavourite;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpacing.space4,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: CoreShadows.small,
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: CoreSpacing.space4,
              vertical: CoreSpacing.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: CoreSpacing.space1),
                // Handle indicator
                Center(
                  child: Container(
                    width: CoreSpacing.space10,
                    height: CoreSpacing.space1,
                    decoration: BoxDecoration(
                      color: CoreTextColors.disable,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: CoreSpacing.space4),
                const SizedBox(height: CoreSpacing.space3),
                // Title
                Text(
                  estimationName,
                  style: CoreTypography.titleMediumSemiBold(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Quick actions row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
            child: Column(
              spacing: CoreSpacing.space8,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickActionButton(
                      icon: CoreIcons.editDocument,
                      label: 'Rename',
                      onTap: onRename,
                    ),
                    _QuickActionButton(
                      icon: isFavourite
                          ? CoreIcons.favorite
                          : CoreIcons.favorite,
                      label: 'Favourite',
                      onTap: onFavourite,
                      iconColor: isFavourite ? CoreIconColors.red : null,
                    ),
                    _QuickActionButton(
                      icon: CoreIcons.delete,
                      label: 'Remove',
                      onTap: onRemove,
                    ),
                  ],
                ),
                Divider(color: CoreBorderColors.lineMid, thickness: 1),
                Column(children: []),
              ],
            ),
          ),
          SizedBox(height: CoreSpacing.space4),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final CoreIconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpacing.space2,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: CoreBorderColors.lineLight),
            ),
            child: Center(
              child: CoreIconWidget(
                icon: icon,
                size: 24,
                color: CoreButtonColors.surface,
              ),
            ),
          ),
          Text(
            label,
            style: CoreTypography.bodyLargeRegular(color: CoreTextColors.body),
          ),
        ],
      ),
    );
  }
}
