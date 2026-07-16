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
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}
