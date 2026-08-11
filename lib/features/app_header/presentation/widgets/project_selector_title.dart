import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Tappable project-selector title: the current project/app title followed
/// by a dropdown chevron, shared by [HeaderRow] and [TitleSearchAppBar].
class ProjectSelectorTitle extends StatelessWidget {
  /// Key applied to the tappable [InkWell], distinct per call site for
  /// widget/golden tests.
  final Key? selectorKey;

  /// Called when the title is tapped to open the project selector.
  final VoidCallback? onProjectTap;

  /// Text style for the title; falls back to the default [Text] style.
  final TextStyle? textStyle;

  const ProjectSelectorTitle({
    super.key,
    this.selectorKey,
    this.onProjectTap,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final coreColors = context.colorTheme;
    return Semantics(
      label: context.l10n.projectDropdownSemanticLabel,
      button: true,
      child: InkWell(
        key: selectorKey,
        onTap: onProjectTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                context.l10n.appTitle,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: CoreSpacing.space1),
            CoreIconWidget(
              icon: CoreIcons.arrowDropDown,
              color: coreColors.iconGrayMid,
              size: CoreIconSize.size24,
            ),
          ],
        ),
      ),
    );
  }
}
