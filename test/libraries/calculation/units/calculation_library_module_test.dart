import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/calculation/calculation_library_module.dart';
import 'package:construculator/libraries/calculation/data/data_source/interfaces/local_calculation_session_data_source.dart';
import 'package:construculator/libraries/calculation/domain/repositories/calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../helpers/fake_calculation_sessions_database.dart';

void main() {
  // One database and one wrapper for the file: Modular keeps an imported
  // module's injector across Modular.destroy, so every test reads the
  // first test's bootstrap; each test reseeds them instead.
  final database = FakeCalculationSessionsDatabase();
  final supabase = FakeSupabaseWrapper(
    clock: FakeClockImpl(DateTime.utc(2026, 11, 25)),
  );

  group('CalculationLibraryModule', () {
    setUp(() {
      database.tables.clear();
      supabase.setInternalUserId('user-1');
      Modular.init(
        _CalculationTestModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: supabase,
            powerSyncDatabase: database,
          ),
        ),
      );
    });

    tearDown(() {
      Modular.destroy();
    });

    tearDownAll(() async {
      await database.closeChanges();
      supabase.dispose();
    });

    test('exports the data source and the repository over the app\'s '
        'PowerSync database, and a bank through the real chain lands in the '
        'two tables', () async {
      expect(
        Modular.get<LocalCalculationSessionDataSource>(),
        same(Modular.get<LocalCalculationSessionDataSource>()),
      );
      final repository = Modular.get<CalculationSessionRepository>();
      expect(repository, same(Modular.get<CalculationSessionRepository>()));

      final typed = (const Tape().typeDigit('2') as TapeChanged).tape;
      final result = await repository.bankSession(typed);
      expect(result.isRight(), isTrue);
      expect(database.tables['calculator_sessions'], hasLength(1));
      expect(database.tables['calculator_tapes'], hasLength(1));
      expect(
        database.tables['calculator_sessions']!.single['creator_user_id'],
        'user-1',
      );
    });

    test('with nobody signed in the module\'s repository refuses a bank as '
        'notSignedIn and writes nothing', () async {
      supabase.setInternalUserId(null);
      final repository = Modular.get<CalculationSessionRepository>();
      final typed = (const Tape().typeDigit('2') as TapeChanged).tape;
      final result = await repository.bankSession(typed);
      expect(
        result.fold(
          (failure) =>
              failure ==
              const CalculatorFailure(
                errorType: CalculatorErrorType.notSignedIn,
              ),
          (_) => false,
        ),
        isTrue,
      );
      expect(database.tables['calculator_sessions'], anyOf(isNull, isEmpty));
      expect(database.tables['calculator_tapes'], anyOf(isNull, isEmpty));
    });
  });
}

class _CalculationTestModule extends Module {
  final AppBootstrap appBootstrap;

  _CalculationTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [CalculationLibraryModule(appBootstrap)];
}
