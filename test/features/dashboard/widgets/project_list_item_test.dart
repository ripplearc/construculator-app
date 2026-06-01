import 'package:construculator/features/dashboard/presentation/widgets/project_list_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  Project buildProject({
    String id = 'project-1',
    String projectName = 'My project',
    DateTime? updatedAt,
  }) {
    final timestamp = updatedAt ?? DateTime(2025, 4, 29, 18, 11);
    return Project(
      id: id,
      projectName: projectName,
      creatorUserId: 'user-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: timestamp,
      status: ProjectStatus.active,
    );
  }

  Widget buildTestApp({
    required Project project,
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onSettingsTap,
  }) {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProjectListItem(
          project: project,
          isSelected: isSelected,
          onTap: onTap,
          onSettingsTap: onSettingsTap,
        ),
      ),
    );
  }

  testWidgets('renders project name and formatted updated date and time', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        project: buildProject(
          projectName: 'Material of building',
          updatedAt: DateTime(2025, 5, 6, 14, 30),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Material of building'), findsOneWidget);
    expect(find.text('May 6, 2025 • 2:30 pm'), findsOneWidget);
  });

  testWidgets('invokes onTap when the card is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      buildTestApp(project: buildProject(), onTap: () => tapped = true),
    );
    await tester.pump();

    await tester.tap(find.text('My project'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onSettingsTap when the settings icon is tapped', (
    tester,
  ) async {
    var settingsTapped = false;
    await tester.pumpWidget(
      buildTestApp(
        project: buildProject(),
        onSettingsTap: () => settingsTapped = true,
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Project settings'));
    await tester.pump();

    expect(settingsTapped, isTrue);
  });

  double borderWidthOf(WidgetTester tester) {
    final card = tester.widget<Container>(
      find.byKey(const Key('project_list_item_card')),
    );
    final decoration = card.decoration as BoxDecoration;
    final border = decoration.border as Border;
    return border.top.width;
  }

  testWidgets('uses a thicker highlighted border when selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(project: buildProject(), isSelected: true),
    );
    await tester.pump();

    expect(borderWidthOf(tester), 2);
  });

  testWidgets('uses a thin border when not selected', (tester) async {
    await tester.pumpWidget(
      buildTestApp(project: buildProject(), isSelected: false),
    );
    await tester.pump();

    expect(borderWidthOf(tester), 1);
  });
}
