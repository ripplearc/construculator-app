import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Taps the [CoreButton] with [key] once it is enabled.
///
/// A [CoreButton] that is disabled is still on screen, so a plain
/// `$(key).tap()` succeeds on it and does nothing. That silently skips the
/// step, and the test then fails much later on something the skipped tap was
/// meant to cause. Matching only an enabled button makes Patrol keep waiting,
/// up to the test's `visibleTimeout`, and fail here with this finder's
/// description if the button never becomes enabled.
Future<void> tapWhenEnabled(PatrolIntegrationTester $, Key key) async {
  final enabledButton = find.byWidgetPredicate(
    (widget) => widget is CoreButton && widget.key == key && !widget.isDisabled,
    description: 'enabled CoreButton with key $key',
  );
  await $(enabledButton).tap();
}
