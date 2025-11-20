import 'package:construculator/libraries/mixins/localization_mixin.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';

class EstimationActionsSheet extends StatefulWidget {
  const EstimationActionsSheet({
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
  State<EstimationActionsSheet> createState() => _EstimationActionsSheetState();
}

class _EstimationActionsSheetState extends State<EstimationActionsSheet>
    with LocalizationMixin {
  @override
  Widget build(BuildContext context) {
    final colorTheme = AppColorsExtension.of(context);
    final typographyTheme = AppTypographyExtension.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
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
              color: colorTheme.pageBackground,
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
                Center(
                  child: Container(
                    width: CoreSpacing.space10,
                    height: CoreSpacing.space1,
                    decoration: BoxDecoration(
                      color: colorTheme.textDisable,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: CoreSpacing.space4),
                const SizedBox(height: CoreSpacing.space3),

                Text(
                  widget.estimationName,
                  style: typographyTheme.titleMediumSemiBold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

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
                      label: l10n.renameAction,
                      onTap: widget.onRename,
                    ),
                    _QuickActionButton(
                      icon: widget.isFavourite
                          ? CoreIcons.favorite
                          : CoreIcons.favorite,
                      label: l10n.favouriteAction,
                      onTap: widget.onFavourite,
                      iconColor: widget.isFavourite ? CoreIconColors.red : null,
                    ),
                    _QuickActionButton(
                      icon: CoreIcons.delete,
                      label: l10n.removeAction,
                      onTap: widget.onRemove,
                    ),
                  ],
                ),
                Divider(color: colorTheme.lineMid, thickness: 1),
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
    final colorTheme = AppColorsExtension.of(context);
    final typographyTheme = AppTypographyExtension.of(context);
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
              color: colorTheme.pageBackground,
              shape: BoxShape.circle,
              border: Border.all(color: colorTheme.lineLight),
            ),
            child: Center(
              child: CoreIconWidget(
                icon: icon,
                size: 24,
                color: colorTheme.buttonSurface,
              ),
            ),
          ),
          Text(label, style: typographyTheme.bodyLargeRegular),
        ],
      ),
    );
  }
}
