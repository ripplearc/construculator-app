import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A bottom sheet that looks like [CoreQuickSheet] but sends a swipe down on
/// its grey handle through [Navigator.maybePop], so a [PopScope] inside the
/// sheet can ask before it closes. [CoreQuickSheet] either closes on that swipe
/// without asking or ignores it.
///
// TODO: [CA-1317] replace with CoreQuickSheet once it can send a swipe on its handle through maybePop. https://ripplearc.youtrack.cloud/issue/CA-1317
class GuardedQuickSheet extends StatelessWidget {
  /// Key of the grey handle area.
  static const handleKey = Key('guarded_quick_sheet_handle');

  static const double _swipeDownVelocity = 700;
  static const double _maxHeightRatio = 0.9;
  static const double _cornerRadius = 28;
  static const double _handleWidth = CoreSpacing.space8;
  static const double _handleHeight = CoreSpacing.space1;

  /// The sheet's content, drawn under the handle.
  final Widget child;

  /// The fill of the sheet.
  final Color backgroundColor;

  const GuardedQuickSheet({
    super.key,
    required this.child,
    required this.backgroundColor,
  });

  /// Shows [child] in a sheet whose handle swipe asks before closing, and
  /// returns what the sheet is popped with.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    required Color backgroundColor,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: context.colorTheme.transparent,
    builder: (_) =>
        GuardedQuickSheet(backgroundColor: backgroundColor, child: child),
  );

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * _maxHeightRatio;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(_cornerRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              key: handleKey,
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > _swipeDownVelocity) {
                  Navigator.of(context).maybePop();
                }
              },
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: CoreSpacing.space4,
                  ),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colorTheme.lineDarkOutline,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const SizedBox(
                        width: _handleWidth,
                        height: _handleHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
