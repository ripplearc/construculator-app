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

  testWidgets('renders Edit project label when onPressed is set', (tester) async {
    await tester.pumpWidget(buildTestApp(onPressed: () async {}));
    await tester.pump();

    expect(find.text('Edit project'), findsOneWidget);
    expect(find.byType(CoreButton), findsOneWidget);
  });

  testWidgets('is hidden entirely when onPressed is null', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.byType(CoreButton), findsNothing);
    expect(find.text('Edit project'), findsNothing);
  });

  testWidgets('calls onPressed exactly once when tapped', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      buildTestApp(onPressed: () async { callCount++; }),
    );
    await tester.pump();

    await tester.tap(find.byType(CoreButton));
    await tester.pump();

    expect(callCount, 1);
  });

  testWidgets('disables button while onPressed is in flight', (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      buildTestApp(onPressed: () => completer.future),
    );
    await tester.pump();

    await tester.tap(find.byType(CoreButton));
    await tester.pump();

    expect(
      tester.widget<CoreButton>(find.byType(CoreButton)).isDisabled,
      isTrue,
    );

    completer.complete();
    await tester.pumpAndSettle();

    expect(
      tester.widget<CoreButton>(find.byType(CoreButton)).isDisabled,
      isFalse,
    );
  });

  testWidgets('ignores second tap while onPressed is in flight', (tester) async {
    var callCount = 0;
    final completer = Completer<void>();
    await tester.pumpWidget(
      buildTestApp(onPressed: () {
        callCount++;
        return completer.future;
      }),
    );
    await tester.pump();

    await tester.tap(find.byType(CoreButton));
    await tester.pump();

    await tester.tap(find.byType(CoreButton));
    await tester.pump();

    expect(callCount, 1);

    completer.complete();
    await tester.pump();
  });

  testWidgets('exposes semantics button with Edit project label', (tester) async {
    await tester.pumpWidget(buildTestApp(onPressed: () async {}));
    await tester.pump();

    expect(find.bySemanticsLabel('Edit project'), findsOneWidget);
  });
}
