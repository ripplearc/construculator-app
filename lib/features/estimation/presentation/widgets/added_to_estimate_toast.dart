import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The dark "Added to Bedroom 2" toast shown after a cost line is added.
// TODO: [CA-1256] use a CoreUI dark success toast instead of these hardcoded numbers. https://ripplearc.youtrack.cloud/issue/CA-1256
class AddedToEstimateToast extends StatelessWidget {
  final String message;

  const AddedToEstimateToast({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? colors.backgroundGrayMid : colors.backgroundDarkGray;
    final onFill = isDark ? colors.textHeadline : colors.textInverse;
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.shadowGrey18,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.statusSuccess,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(CoreSpacing.space1),
                    child: CoreIconWidget(
                      icon: CoreIcons.checkMark,
                      size: CoreIconSize.size16,
                      color: onFill,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    message,
                    style: context.textTheme.bodyMediumSemiBold.copyWith(
                      color: onFill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
