import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAppAtRoute(
  WidgetTester tester,
  Widget app,
  String route,
) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  Modular.to.navigate(route);
  // ModularRouterDelegate.navigate debounces calls made within 500ms of the
  // previous one (measured on the wall clock) by scheduling a
  // Future.delayed(500 - diff) before routing; pump past the full 500ms so the
  // timer always fires regardless of how fast the previous test ran.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}
