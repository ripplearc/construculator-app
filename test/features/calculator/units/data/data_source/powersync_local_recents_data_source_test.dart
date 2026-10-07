import 'package:async/async.dart';
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
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(dataSource.watchRecents('Height'));
      expect(await events.next, <Quantity>[]);
      await dataSource.replaceRecents('Height', [eightFeet]);
      expect(await events.next, [eightFeet]);
      await dataSource.replaceRecents('angle', [angle]);
      await dataSource.replaceRecents('Height', [tenFeet, eightFeet]);
      expect(await events.next, [tenFeet, eightFeet]);
      await events.cancel();
    });

    test('a watch skips a replacement that changes nothing', () async {
      await dataSource.replaceRecents('Height', [eightFeet]);
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(dataSource.watchRecents('Height'));
      expect(await events.next, [eightFeet]);
      await dataSource.replaceRecents('Height', [eightFeet]);
      await dataSource.replaceRecents('Height', [tenFeet]);
      expect(await events.next, [tenFeet]);
      await events.cancel();
    });

    test(
      'a replacement that fails throws and leaves the drawer as it was',
      () async {
        await dataSource.replaceRecents('Height', [eightFeet]);
        database.writeError = StateError('locked');
        await expectLater(
          () => dataSource.replaceRecents('Height', [tenFeet]),
          throwsA(isA<StateError>()),
        );
        database.writeError = null;
        expect(await dataSource.fetchRecents('Height'), [eightFeet]);
      },
    );

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
        final recents = dataSource.watchRecents('Height');
        final ended = expectLater(
          recents,
          emitsInOrder([<Quantity>[], emitsDone]),
        );
        await expectLater(recents, emits(<Quantity>[]));
        await dataSource.dispose();
        await ended;
        expect(await dataSource.fetchRecents('Height'), isEmpty);
      },
    );

    test('dispose closes a watch even when the database refuses to let it go, '
        'and throws the refusal', () async {
      final recents = dataSource.watchRecents('Height');
      final ended = expectLater(
        recents,
        emitsInOrder([<Quantity>[], emitsDone]),
      );
      await expectLater(recents, emits(<Quantity>[]));
      database.cancelError = StateError('busy');
      await expectLater(dataSource.dispose(), throwsStateError);
      await ended;
    });

    test('a watch taken after dispose answers once and ends', () async {
      await dataSource.dispose();
      expect(await dataSource.watchRecents('Height').toList(), [<Quantity>[]]);
    });
  });
}
