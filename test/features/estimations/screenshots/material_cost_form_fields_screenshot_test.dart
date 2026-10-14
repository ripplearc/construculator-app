import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390.0, 300.0);
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;
  late FakeStorageService storage;
  late FakeAuthRepository auth;
  late MaterialCostFormBloc bloc;

  setUpAll(() {
    final clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    storage = FakeStorageService();
    auth = FakeAuthRepository(clock: clock);
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
    Modular.replaceInstance<StorageService>(storage);
    Modular.replaceInstance<AuthRepository>(auth);
  });

  tearDownAll(Modular.dispose);

  setUp(() async {
    fakeSupabase.reset();
    storage.reset();
    auth.reset();
    auth.setCurrentCredentials(
      UserCredential(
        id: 'account-1',
        email: 'a@example.com',
        metadata: const {},
        createdAt: DateTime(2026),
      ),
    );
    await loadAppFontsAll();
  });

  Future<void> pumpFields(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    bloc = Modular.get<MaterialCostFormBloc>();
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<MaterialCostFormBloc>.value(
            value: bloc,
            child: const MaterialCostFormFields(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAllFields(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('material_name_field')),
      'Interior paint',
    );
    await tester.enterText(
      find.byKey(const Key('material_quantity_field')),
      '7',
    );
    await tester.enterText(find.byKey(const Key('material_rate_field')), '52');
    bloc.add(const MaterialUnitSelected(Unit.liters));
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('MaterialCostFormFields Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders the empty form', (tester) async {
      await pumpFields(tester, theme);

      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/material_empty$suffix.png',
        ),
      );
    });

    testWidgets('renders the filled form', (tester) async {
      await pumpFields(tester, theme);
      await fillAllFields(tester);

      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/material_filled$suffix.png',
        ),
      );
    });

    testWidgets('renders the fields locked while the line saves', (
      tester,
    ) async {
      await pumpFields(tester, theme);
      await fillAllFields(tester);
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();
      bloc.add(const MaterialCostFormSubmitted(estimateId: 'estimate-1'));
      await tester.pump();
      await tester.pump();

      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/material_saving$suffix.png',
        ),
      );

      fakeSupabase.completer!.complete();
      fakeSupabase.shouldDelayOperations = false;
      await tester.pumpAndSettle();
    });
  });
}
