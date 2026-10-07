import 'package:construculator/features/calculator/data/data_source/powersync_local_recents_data_source.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late PowerSyncLocalRecentsDataSource dataSource;

  const eightFeet = Length(8 * Length.ticksPerFoot, unit: Unit.foot);
  const tenFeet = Length(10 * Length.ticksPerFoot, unit: Unit.foot);
  const twelveFeet = Length(12 * Length.ticksPerFoot, unit: Unit.foot);
  const angle = Angle(38.05);

  setUp(() {
    database = FakeTradeStoresDatabase();
    // The subject under test; resolving it through Modular would test the
    // module binding instead.
    // ignore: no_direct_instantiation
    dataSource = PowerSyncLocalRecentsDataSource(database: database);
  });

  tearDown(() async {
    await dataSource.dispose();
    await database.closeChanges();
  });

  group('PowerSyncLocalRecentsDataSource', () {
    test('a drawer nothing was filed in is empty', () async {
      expect(await dataSource.fetchRecents('Height'), isEmpty);
    });

    test('replaces a drawer and reads it back newest first', () async {
      await dataSource.replaceRecents('Height', [eightFeet, tenFeet]);
      expect(await dataSource.fetchRecents('Height'), [eightFeet, tenFeet]);
      await dataSource.replaceRecents('Height', [
        twelveFeet,
        eightFeet,
        tenFeet,
      ]);
      expect(await dataSource.fetchRecents('Height'), [
        twelveFeet,
        eightFeet,
        tenFeet,
      ]);
    });

    test('keeps one drawer apart from another', () async {
      await dataSource.replaceRecents('Height', [eightFeet]);
      await dataSource.replaceRecents('angle', [angle]);
      await dataSource.replaceRecents('Height', const []);
      expect(await dataSource.fetchRecents('Height'), isEmpty);
      expect(await dataSource.fetchRecents('angle'), [angle]);
    });

    test('a watch emits the drawer now and after each replacement', () async {
      final expectation = expectLater(
        dataSource.watchRecents('Height'),
        emitsInOrder([
          <Quantity>[],
          [eightFeet],
          [tenFeet, eightFeet],
        ]),
      );
      await dataSource.replaceRecents('Height', [eightFeet]);
      await pumpEventQueue();
      await dataSource.replaceRecents('angle', [angle]);
      await pumpEventQueue();
      await dataSource.replaceRecents('Height', [tenFeet, eightFeet]);
      await expectation;
    });

    test('a watch skips a replacement that changes nothing', () async {
      await dataSource.replaceRecents('Height', [eightFeet]);
      await pumpEventQueue();
      final seen = <List<Quantity>>[];
      final subscription = dataSource.watchRecents('Height').listen(seen.add);
      await dataSource.replaceRecents('Height', [eightFeet]);
      await pumpEventQueue();
      await dataSource.replaceRecents('Height', [tenFeet]);
      await pumpEventQueue();
      await subscription.cancel();
      expect(seen, [
        [eightFeet],
        [tenFeet],
      ]);
    });

    test('a read that fails throws to the caller', () async {
      database.readError = StateError('locked');
      await expectLater(
        () => dataSource.fetchRecents('Height'),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'dispose ends the watches handed out and leaves the database usable',
      () async {
        var done = false;
        dataSource
            .watchRecents('Height')
            .listen((_) {}, onDone: () => done = true);
        await pumpEventQueue();
        await dataSource.dispose();
        await pumpEventQueue();
        expect(done, isTrue);
        expect(await dataSource.fetchRecents('Height'), isEmpty);
      },
    );

    test('a watch taken after dispose answers once and ends', () async {
      await dataSource.dispose();
      expect(await dataSource.watchRecents('Height').toList(), [<Quantity>[]]);
    });
  });
}
