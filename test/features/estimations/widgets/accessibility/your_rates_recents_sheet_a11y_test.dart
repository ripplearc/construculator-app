import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_recents_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_your_rates_database.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late FakeClockImpl clock;

  setUpAll(() {
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    database = FakeYourRatesDatabase();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
    Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    database.reset();
    Modular.get<CurrentCompanyResolver>().clearCache();
    fakeSupabase.setRpcResponse(
      DatabaseConstants.getMyCompanyIdRpcFunction,
      'company-1',
    );
    database.seedRows([
      {
        'id': 'rate-1',
        'company_id': 'company-1',
        'category': 'equipment',
        'item_name': 'Scissor lift — 19ft',
        'rate_amount': 120,
        'rate_currency': 'USD',
        'equipment_method': 'day',
        'saved_at': clock
            .now()
            .subtract(const Duration(days: 60))
            .toIso8601String(),
        'last_used_at': clock
            .now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
      },
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
    database.reset();
  });

  Widget makeWidget(
    ThemeData theme, {
    CostItemType category = CostItemType.equipment,
  }) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<YourRatesBloc>(
          create: (_) => Modular.get<YourRatesBloc>(),
          child: YourRatesRecentsSheet(clock: clock, category: category),
        ),
      ),
    );
  }

  group('YourRatesRecentsSheet – accessibility', () {
    testWidgets(
      'a11y: a recent row meets tap target and label guidelines in both '
      'themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('your_rate_row_rate-1')),
        );
      },
    );

    testWidgets(
      'a11y: "New equipment cost" meets tap target and label guidelines in '
      'both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('new_cost_row')),
        );
      },
    );

    testWidgets(
      'a11y: the search box meets tap target and label guidelines in both '
      'themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('your_rates_search_field')),
        );
      },
    );

    testWidgets(
      'a11y: the Create row for a typed name meets tap target and label '
      'guidelines',
      (tester) async {
        await setupA11yTest(tester);
        await tester.pumpWidget(makeWidget(CoreTheme.light()));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('your_rates_search_field')),
            matching: find.byType(EditableText),
          ),
          'mini excavator',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.byKey(const Key('create_typed_name_row')),
        );
      },
    );

    testWidgets(
      'a11y: "Try again" on the failed-read message meets tap target and label '
      'guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        database.getAllError = StateError('database locked');

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('your_rates_recents_try_again_button')),
        );
      },
    );

    testWidgets('a11y: the failed-read message is a live region so a screen '
        'reader reads it when the sheet opens', (tester) async {
      await setupA11yTest(tester);
      database.getAllError = StateError('database locked');
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Couldn’t open your saved prices.')),
        isSemantics(isLiveRegion: true),
      );
      expect(
        tester.getSemantics(
          find.text(
            lookupAppLocalizations(
              const Locale('en'),
            ).yourRatesRecentsLoadErrorHint,
          ),
        ),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('a11y: a retry that fails again announces the failed-read '
        'message, and opening the sheet does not', (tester) async {
      await setupA11yTest(tester);
      database.getAllError = StateError('database locked');
      final announcements = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockDecodedMessageHandler<dynamic>(
        SystemChannels.accessibility,
        (message) async {
          final event = message as Map<Object?, Object?>;
          if (event['type'] == 'announce') {
            final data = event['data']! as Map<Object?, Object?>;
            announcements.add(data['message']! as String);
          }
          return null;
        },
      );
      addTearDown(
        () => messenger.setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await tester.pumpAndSettle();
      expect(announcements, isEmpty);

      await tester.tap(
        find.byKey(const Key('your_rates_recents_try_again_button')),
      );
      await tester.pumpAndSettle();

      expect(announcements, [
        '${l10n.yourRatesLoadError} ${l10n.yourRatesRecentsLoadErrorHint}',
      ]);
    });

    testWidgets(
      'a11y: a material row and "New material cost" meet tap target and '
      'label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        database.seedRows([
          {
            'id': 'paint-rate',
            'company_id': 'company-1',
            'category': 'material',
            'item_name': 'Interior paint',
            'rate_amount': 52.0,
            'rate_currency': 'USD',
            'unit': 'liters',
            'saved_at': clock.now().toIso8601String(),
          },
        ]);
        Widget materialSheet(ThemeData theme) =>
            makeWidget(theme, category: CostItemType.material);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          materialSheet,
          find.byKey(const Key('your_rate_row_paint-rate')),
        );
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          materialSheet,
          find.byKey(const Key('new_cost_row')),
        );
      },
    );
  });
}
