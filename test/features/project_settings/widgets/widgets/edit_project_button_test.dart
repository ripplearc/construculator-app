import 'dart:async';

import 'package:construculator/features/project_settings/presentation/widgets/edit_project_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget buildTestApp({Future<void> Function()? onPressed}) {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: EditProjectButton(onPressed: onPressed),
        ),
      ),
    );
  }

  testWidgets('renders edit icon when idle', (tester) async {
    await tester.pumpWidget(buildTestApp(onPressed: () async {}));
    await tester.pump();

    expect(find.byKey(const Key('edit_project_icon')), findsOneWidget);
    expect(find.byKey(const Key('edit_project_loading')), findsNothing);
  });

  testWidgets('shows loading indicator while onPressed is in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(buildTestApp(onPressed: () => completer.future));
    await tester.pump();

    await tester.tap(find.byType(EditProjectButton));
    await tester.pump();

    expect(find.byKey(const Key('edit_project_loading')), findsOneWidget);
    expect(find.byKey(const Key('edit_project_icon')), findsNothing);

    completer.complete();
    await tester.pump();

    expect(find.byKey(const Key('edit_project_loading')), findsNothing);
    expect(find.byKey(const Key('edit_project_icon')), findsOneWidget);
  });

  testWidgets('calls onPressed exactly once when tapped', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      buildTestApp(onPressed: () async { callCount++; }),
    );
    await tester.pump();

    await tester.tap(find.byType(EditProjectButton));
    await tester.pump();

    expect(callCount, 1);
  });

  testWidgets('ignores second tap while onPressed is in flight', (
    tester,
  ) async {
    var callCount = 0;
    final completer = Completer<void>();
    await tester.pumpWidget(
      buildTestApp(onPressed: () {
        callCount++;
        return completer.future;
      }),
    );
    await tester.pump();

    await tester.tap(find.byType(EditProjectButton));
    await tester.pump();

    await tester.tap(find.byType(EditProjectButton));
    await tester.pump();

    expect(callCount, 1);

    completer.complete();
    await tester.pump();
  });

  testWidgets(
    'exposes semantics button with edit project label when onPressed set',
    (tester) async {
      await tester.pumpWidget(buildTestApp(onPressed: () async {}));
      await tester.pump();

      expect(find.bySemanticsLabel('Edit project'), findsOneWidget);
    },
  );

  testWidgets('is hidden entirely when onPressed is null', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.byKey(const Key('edit_project_icon')), findsNothing);
    expect(find.bySemanticsLabel('Edit project'), findsNothing);
  });

  testWidgets('hit target is 48 × 48 points to satisfy a11y guidelines', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(onPressed: () async {}));
    await tester.pump();

    final box = tester.getRect(find.byType(EditProjectButton));
    expect(box.width, CoreSpacing.space12);
    expect(box.height, CoreSpacing.space12);
  });
}
