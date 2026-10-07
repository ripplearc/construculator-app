import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The header row of a bottom sheet: a back arrow on the left, then a title
/// with an optional line under it.
///
/// The back arrow closes the sheet, unless the sheet holds a [PopScope] that
/// asks first. Every sheet in the equipment flow uses
/// this one header, so the arrow and the text spacing match in all of them.
class SheetHeader extends StatelessWidget {
  /// Key of the back arrow, so tests and screen readers can find it.
  static const backButtonKey = Key('sheet_back_button');

  /// The main line, in semibold. A long title is cut off with an ellipsis.
  final String title;

  /// An optional second line under [title], in regular weight. When null, no
  /// second line is drawn.
  final String? subtitle;

  const SheetHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final subtitleText = subtitle;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoreIconWidget(
          key: backButtonKey,
          icon: CoreIcons.arrowLeft,
          color: colorTheme.textLink,
          padding: const EdgeInsets.all(CoreSpacing.space3),
          size: CoreIconSize.size24,
          semanticLabel: context.l10n.backLabel,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Padding(
            // TODO: [CA-1238] use the CoreUI sheet header and spacing tokens once they exist. https://ripplearc.youtrack.cloud/issue/CA-1238
            padding: const EdgeInsets.only(
              top: 11,
              right: CoreSpacing.space5,
              bottom: 15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMediumSemiBold.copyWith(
                    color: colorTheme.textHeadline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleText != null)
                  Text(
                    subtitleText,
                    style: textTheme.bodyMediumRegular.copyWith(
                      color: colorTheme.textBody,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
