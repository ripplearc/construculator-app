import 'dart:async';

import 'package:construculator/features/dashboard/presentation/widgets/view_project_details_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Widget buildTestApp({Future<void> Function()? onPressed}) {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: ViewProjectDetailsButton(onPressed: onPressed),
        ),
      ),
    );
  }

  testWidgets('renders settings icon when idle', (tester) async {
    await tester.pumpWidget(buildTestApp(onPressed: () async {}));
    await tester.pump();

    expect(find.byKey(const Key('view_project_details_icon')), findsOneWidget);
    expect(
      find.byKey(const Key('view_project_details_loading')),
      findsNothing,
    );
  });

  testWidgets('shows loading indicator while onPressed is in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      buildTestApp(onPressed: () => completer.future),
    );
    await tester.pump();

    await tester.tap(find.byType(ViewProjectDetailsButton));
    await tester.pump();

    expect(
      find.byKey(const Key('view_project_details_loading')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('view_project_details_icon')), findsNothing);

    completer.complete();
    await tester.pump();

    expect(
      find.byKey(const Key('view_project_details_loading')),
      findsNothing,
    );
    expect(find.byKey(const Key('view_project_details_icon')), findsOneWidget);
  });

  testWidgets('calls onPressed exactly once when tapped', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(
      buildTestApp(onPressed: () async { callCount++; }),
    );
    await tester.pump();

    await tester.tap(find.byType(ViewProjectDetailsButton));
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

    await tester.tap(find.byType(ViewProjectDetailsButton));
    await tester.pump();

    await tester.tap(find.byType(ViewProjectDetailsButton));
    await tester.pump();

    expect(callCount, 1);

    completer.complete();
    await tester.pump();
  });

}
