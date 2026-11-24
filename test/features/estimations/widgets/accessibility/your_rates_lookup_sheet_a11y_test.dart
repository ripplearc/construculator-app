import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_lookup_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_your_rates_database.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeYourRatesDatabase database;
  late FakeClockImpl clock;

  setUpAll(() {
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    database = FakeYourRatesDatabase();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
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
        'item_name': 'Dumpster — 30 yd',
        'rate_amount': 400,
        'rate_currency': 'USD',
        'equipment_method': 'job',
        'saved_at': DateTime(2025, 12, 1).toIso8601String(),
        'last_used_at': DateTime(2026, 1, 8).toIso8601String(),
      },
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
    database.reset();
  });

  Widget makeWidget(
    ThemeData theme, {
    EquipmentPricingMethod method = EquipmentPricingMethod.job,
  }) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<YourRatesBloc>(
          create: (_) => Modular.get<YourRatesBloc>(),
          child: YourRatesLookupSheet(
            method: method,
            onSwitchMethod: (_) {},
            clock: clock,
          ),
        ),
      ),
    );
  }

  group('YourRatesLookupSheet – accessibility', () {
    testWidgets('a11y: a saved rate row meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(const Key('your_rate_row_rate-1')),
      );
    });

    testWidgets('a11y: the other-method action meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeWidget(theme, method: EquipmentPricingMethod.day),
        find.byKey(const Key('your_rates_other_method_action')),
        setupAfterPump: (tester) async {
          await tester.enterText(
            find.byKey(CoreSearchBox.textFieldKey),
            'dumpster',
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('a11y: "Try again" on the failed-read message meets tap target '
        'and label guidelines in both themes', (tester) async {
      await setupA11yTest(tester);
      database.getAllError = StateError('database locked');

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(const Key('your_rates_try_again_button')),
      );
    });

    testWidgets('a11y: "Try again" on the failed-read message is a labelled '
        'button with a 48 x 48 dp zone', (tester) async {
      await setupA11yTest(tester);
      database.getAllError = StateError('database locked');
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await tester.pumpAndSettle();

      final zone = tester.getSize(
        find.byKey(const Key('your_rates_try_again_button')),
      );
      expect(zone.width, greaterThanOrEqualTo(48));
      expect(zone.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(find.bySemanticsLabel(_l10n.yourRatesTryAgain)),
        isSemantics(
          label: _l10n.yourRatesTryAgain,
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a11y: the failed-read message is a live region so a screen '
        'reader reads it when it appears', (tester) async {
      await setupA11yTest(tester);
      database.getAllError = StateError('database locked');
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text(_l10n.yourRatesLoadError)),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('a11y: while the retry runs, "Try again" is a disabled button '
        'with a 48 x 48 dp zone and the message stays a live region', (
      tester,
    ) async {
      await setupA11yTest(tester);
      database.getAllError = StateError('database locked');
      final handle = tester.ensureSemantics();
      final gate = Completer<void>();
      try {
        await tester.pumpWidget(makeWidget(CoreTheme.light()));
        await tester.pumpAndSettle();
        database.getAllError = null;
        database.getAllGate = gate;

        await tester.tap(find.byKey(const Key('your_rates_try_again_button')));
        await tester.pumpAndSettle();

        final zone = tester.getSize(
          find.byKey(const Key('your_rates_try_again_button')),
        );
        expect(zone.width, greaterThanOrEqualTo(48));
        expect(zone.height, greaterThanOrEqualTo(48));
        final action = tester
            .getSemantics(find.bySemanticsLabel(_l10n.yourRatesTryAgain))
            .getSemanticsData();
        expect(action.flagsCollection.isButton, isTrue);
        expect(action.flagsCollection.isEnabled, Tristate.isFalse);
        expect(action.hasAction(SemanticsAction.tap), isFalse);
        expect(
          tester.getSemantics(find.text(_l10n.yourRatesLoadError)),
          isSemantics(isLiveRegion: true),
        );
      } finally {
        gate.complete();
        await tester.pumpAndSettle();
        handle.dispose();
      }
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

      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await tester.pumpAndSettle();
      expect(announcements, isEmpty);

      await tester.tap(find.byKey(const Key('your_rates_try_again_button')));
      await tester.pumpAndSettle();

      expect(announcements, [_l10n.yourRatesLoadError]);
    });

    testWidgets('a11y: a second failed retry announces the message again', (
      tester,
    ) async {
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
      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('your_rates_try_again_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('your_rates_try_again_button')));
      await tester.pumpAndSettle();

      expect(announcements, [
        _l10n.yourRatesLoadError,
        _l10n.yourRatesLoadError,
      ]);
    });

    testWidgets('a11y: a retry that works announces nothing', (tester) async {
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
      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await tester.pumpAndSettle();
      database.getAllError = null;

      await tester.tap(find.byKey(const Key('your_rates_try_again_button')));
      await tester.pumpAndSettle();

      expect(announcements, isEmpty);
    });
  });
}
