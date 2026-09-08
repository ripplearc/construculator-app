import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_owner_filter_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

class _OwnerFilterSheetTestModule extends Module {
  final AppBootstrap appBootstrap;

  _OwnerFilterSheetTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [DashboardModule(appBootstrap)];
}

typedef _Owner = ({String id, String firstName, String lastName});

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late ProjectSearchBloc bloc;
  BuildContext? buildContext;

  const defaultOwners = <_Owner>[
    (id: 'owner-ada', firstName: 'Ada', lastName: 'Lovelace'),
    (id: 'owner-alan', firstName: 'Alan', lastName: 'Turing'),
    (id: 'owner-grace', firstName: 'Grace', lastName: 'Hopper'),
  ];

  setUp(() {
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_OwnerFilterSheetTestModule(bootstrap));
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: 'user-1',
        email: 'user@test.com',
        createdAt: DateTime(2024).toIso8601String(),
      ),
    );
  });

  tearDown(() {
    bloc.close();
    fakeSupabase.reset();
    Modular.destroy();
  });

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  void seedOwners(List<_Owner> owners) {
    fakeSupabase.setRpcResponse(
      DatabaseConstants.projectOwnersRpcFunction,
      owners
          .map(
            (owner) => <String, dynamic>{
              DatabaseConstants.idColumn: owner.id,
              DatabaseConstants.credentialIdColumn: null,
              DatabaseConstants.firstNameColumn: owner.firstName,
              DatabaseConstants.lastNameColumn: owner.lastName,
              DatabaseConstants.professionalRoleColumn: 'Engineer',
              DatabaseConstants.profilePhotoUrlColumn: null,
            },
          )
          .toList(),
    );
  }

  /// Pumps a host page whose button opens [ProjectSearchOwnerFilterSheet] via
  /// [CoreQuickSheet], mirroring how the production page presents the sheet.
  Future<void> pumpAndOpenSheet(
    WidgetTester tester, {
    List<_Owner> owners = defaultOwners,
    Set<String> initialSelectedOwnerIds = const {},
  }) async {
    // Create the bloc inside the test zone: a bloc created in setUp lives
    // outside the fake-async zone and its awaits never resume under pump.
    bloc = Modular.get<ProjectSearchBloc>();
    seedOwners(owners);
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return Scaffold(
              body: Center(
                child: CoreFilterChip(
                  key: const Key('open_sheet_button'),
                  label: 'open',
                  onTap: () {
                    bloc.add(
                      const ProjectSearchAvailableOwnersRequestedEvent(),
                    );
                    CoreQuickSheet.show(
                      context: context,
                      child: BlocProvider.value(
                        value: bloc,
                        child: ProjectSearchOwnerFilterSheet(
                          initialSelectedOwnerIds: initialSelectedOwnerIds,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet_button')));
    await tester.pumpAndSettle();
  }

  bool isOwnerChecked(WidgetTester tester, String ownerId) {
    final tile = tester.widget<CheckboxListTile>(
      find.byKey(Key('project_search_owner_filter_item_$ownerId')),
    );
    return tile.value == true;
  }

  group('User on ProjectSearchOwnerFilterSheet', () {
    testWidgets('sees the sheet title and owners listed by full name', (
      tester,
    ) async {
      await pumpAndOpenSheet(tester);

      expect(find.byType(ProjectSearchOwnerFilterSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ProjectSearchOwnerFilterSheet),
          matching: find.text(l10n().projectSearchOwnerSheetTitle),
        ),
        findsOneWidget,
      );
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Alan Turing'), findsOneWidget);
    });

    testWidgets('sees the empty label when no owners are available', (
      tester,
    ) async {
      await pumpAndOpenSheet(tester, owners: const []);

      expect(
        find.byKey(const Key('project_search_owner_filter_empty_label')),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('filters the owner list by full name', (tester) async {
      await pumpAndOpenSheet(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(ProjectSearchOwnerFilterSheet),
          matching: find.byType(TextFormField),
        ),
        'Ada',
      );
      await tester.pump();

      expect(
        find.byKey(const Key('project_search_owner_filter_item_owner-ada')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('project_search_owner_filter_item_owner-alan')),
        findsNothing,
      );
    });

    testWidgets('toggles an owner checkbox on tap', (tester) async {
      await pumpAndOpenSheet(tester);

      expect(isOwnerChecked(tester, 'owner-ada'), isFalse);

      await tester.tap(
        find.byKey(const Key('project_search_owner_filter_item_owner-ada')),
      );
      await tester.pump();
      expect(isOwnerChecked(tester, 'owner-ada'), isTrue);
    });

    testWidgets('pre-checks the initially selected owners', (tester) async {
      await pumpAndOpenSheet(tester, initialSelectedOwnerIds: {'owner-alan'});

      expect(isOwnerChecked(tester, 'owner-alan'), isTrue);
      expect(isOwnerChecked(tester, 'owner-ada'), isFalse);
    });

    testWidgets(
      'Apply dispatches the selection to the bloc and closes the sheet',
      (tester) async {
        await pumpAndOpenSheet(tester);

        await tester.tap(
          find.byKey(const Key('project_search_owner_filter_item_owner-ada')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('project_search_owner_filter_apply_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProjectSearchOwnerFilterSheet), findsNothing);
        final state = bloc.state;
        expect(state, isA<ProjectSearchInitial>());
        expect((state as ProjectSearchInitial).selectedOwnerIds, {'owner-ada'});
      },
    );

    testWidgets('Clear all deselects every owner without closing the sheet', (
      tester,
    ) async {
      await pumpAndOpenSheet(tester);

      await tester.tap(
        find.byKey(const Key('project_search_owner_filter_item_owner-ada')),
      );
      await tester.pump();
      expect(isOwnerChecked(tester, 'owner-ada'), isTrue);

      await tester.tap(
        find.byKey(const Key('project_search_owner_filter_clear_all_button')),
      );
      await tester.pump();

      expect(find.byType(ProjectSearchOwnerFilterSheet), findsOneWidget);
      expect(isOwnerChecked(tester, 'owner-ada'), isFalse);
    });
  });
}
