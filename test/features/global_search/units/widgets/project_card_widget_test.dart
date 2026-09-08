import 'package:construculator/features/global_search/presentation/widgets/project_card_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  final testDate = DateTime(2025, 5, 3, 14, 30);

  Project makeProject({
    String id = 'project-1',
    String projectName = 'Downtown Office Complex',
  }) {
    return Project(
      id: id,
      projectName: projectName,
      creatorUserId: 'user-1',
      createdAt: testDate,
      updatedAt: testDate,
      status: ProjectStatus.active,
    );
  }

  Widget createWidget({Project? project, VoidCallback? onTap}) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProjectCard(
          project: project ?? makeProject(),
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('ProjectCard', () {
    testWidgets('renders the project name', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Downtown Office Complex'), findsOneWidget);
    });

    testWidgets('renders the project and calendar icons', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byKey(const Key('projectIcon')), findsOneWidget);
      expect(find.byKey(const Key('projectCalendarIcon')), findsOneWidget);
    });

    testWidgets('renders the updated date and time via DisplayFormatter',
        (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text(DisplayFormatter.formatDate(testDate)), findsOneWidget);
      expect(find.text(DisplayFormatter.formatTime(testDate)), findsOneWidget);
    });

    testWidgets('invokes onTap when the card is tapped', (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(createWidget(onTap: () => tapCount += 1));

      await tester.tap(find.byKey(const Key('projectCardInkWell')));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('exposes button semantics labeled with the project name',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(createWidget());

      expect(
        find.bySemanticsLabel(RegExp('Downtown Office Complex')),
        findsWidgets,
      );
      handle.dispose();
    });
  });
}
