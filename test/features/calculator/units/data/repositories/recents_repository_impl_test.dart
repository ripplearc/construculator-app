import 'package:construculator/features/calculator/data/data_source/powersync_local_recents_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/recents_repository_impl.dart';
import 'package:construculator/features/calculator/domain/repositories/recents_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late RecentsRepositoryImpl repository;

  const eightFeet = Length(8 * Length.ticksPerFoot, unit: Unit.foot);
  const tenFeet = Length(10 * Length.ticksPerFoot, unit: Unit.foot);
  const angle = Angle(38.05);

  setUp(() {
    database = FakeTradeStoresDatabase();
    // The subject under test with its real data source; only the database
    // is faked, and resolving through Modular would test the binding.
    // ignore: no_direct_instantiation
    repository = RecentsRepositoryImpl(
      // ignore: no_direct_instantiation
      dataSource: PowerSyncLocalRecentsDataSource(database: database),
    );
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('RecentsRepositoryImpl', () {
    test('saves a drawer and watches it back, newest first', () async {
      final expectation = expectLater(
        repository.watchRecents('Height'),
        emitsInOrder([
          <Quantity>[],
          [tenFeet, eightFeet],
        ]),
      );
      final result = await repository.saveRecents('Height', [
        tenFeet,
        eightFeet,
      ]);
      expect(result.isRight(), isTrue);
      await expectation;
    });

    test('keeps the angle drawer apart from a key\'s drawer', () async {
      await repository.saveRecents('Height', [eightFeet]);
      await repository.saveRecents(RecentsRepository.angleDrawer, [angle]);
      expect(await repository.watchRecents('Height').first, [eightFeet]);
      expect(
        await repository.watchRecents(RecentsRepository.angleDrawer).first,
        [angle],
      );
    });

    test('a save the database refuses is a storage failure', () async {
      database.writeError = StateError('locked');
      final result = await repository.saveRecents('Height', [eightFeet]);
      expect(
        result.fold((failure) => failure, (_) => null),
        const CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
    });

    test('dispose ends the watches handed out', () async {
      var done = false;
      repository
          .watchRecents('Height')
          .listen((_) {}, onDone: () => done = true);
      await pumpEventQueue();
      repository.dispose();
      await pumpEventQueue();
      expect(done, isTrue);
    });
  });
}
