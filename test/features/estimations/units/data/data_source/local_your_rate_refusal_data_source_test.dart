import 'package:construculator/features/estimation/data/data_source/interfaces/your_rate_refusal_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/local_your_rate_refusal_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_refusal_dto.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_your_rates_database.dart';

void main() {
  group('LocalYourRateRefusalDataSource', () {
    late FakeYourRatesDatabase database;
    late FakeClockImpl clock;
    late YourRateRefusalDataSource dataSource;

    Map<String, Object?> refusal({
      String itemName = 'Dumpster — 30 yd',
      String? method = 'job',
      double refused = 450.0,
      double? accepted = 400.0,
      String? shownAt,
    }) => {
      'id': YourRateRefusalKey.of(itemName, method),
      'item_name': itemName,
      'equipment_method': method,
      'refused_amount': refused,
      'accepted_amount': accepted,
      'shown_at': shownAt,
    };

    setUp(() {
      database = FakeYourRatesDatabase();
      clock = FakeClockImpl(DateTime.utc(2026, 10, 7, 9));
      Modular.init(_RefusalTestModule(database, clock));
      dataSource = Modular.get<YourRateRefusalDataSource>();
    });

    tearDown(Modular.destroy);

    group('loadAllRefusals', () {
      test('returns every refusal kept on the phone', () async {
        database.seedRefusal(refusal());
        database.seedRefusal(refusal(itemName: 'Excavator', method: 'day'));

        final found = await dataSource.loadAllRefusals();

        expect(found.map((refusal) => refusal.itemName), [
          'Dumpster — 30 yd',
          'Excavator',
        ]);
      });

      test('returns nothing when the server refused nothing', () async {
        expect(await dataSource.loadAllRefusals(), isEmpty);
      });
    });

    group('loadRefusalByItem', () {
      test(
        'returns null when the server refused nothing for the item',
        () async {
          expect(
            await dataSource.loadRefusalByItem('Dumpster — 30 yd', 'job'),
            isNull,
          );
        },
      );

      test('returns the refused and the accepted amounts', () async {
        database.seedRefusal(refusal());

        final found = await dataSource.loadRefusalByItem(
          'Dumpster — 30 yd',
          'job',
        );

        expect(found?.refusedAmount, 450.0);
        expect(found?.acceptedAmount, 400.0);
        expect(found?.shownAt, isNull);
      });

      test(
        'returns a null accepted amount when the server never accepted one',
        () async {
          database.seedRefusal(refusal(accepted: null));

          final found = await dataSource.loadRefusalByItem(
            'Dumpster — 30 yd',
            'job',
          );

          expect(found?.acceptedAmount, isNull);
        },
      );

      test('matches the name ignoring case and extra spaces', () async {
        database.seedRefusal(refusal());

        final found = await dataSource.loadRefusalByItem(
          '  dumpster —  30 YD ',
          'job',
        );

        expect(found, isNotNull);
      });

      test(
        'keeps one pricing method\'s refusal out of the other method\'s read',
        () async {
          database.seedRefusal(refusal(method: 'job'));

          expect(
            await dataSource.loadRefusalByItem('Dumpster — 30 yd', 'day'),
            isNull,
          );
        },
      );
    });

    group('markRefusalShownByItem', () {
      test('stores when the message was shown', () async {
        database.seedRefusal(refusal());

        await dataSource.markRefusalShownByItem('Dumpster — 30 yd', 'job');

        final found = await dataSource.loadRefusalByItem(
          'Dumpster — 30 yd',
          'job',
        );
        expect(found?.shownAt, '2026-10-07T09:00:00.000Z');
      });

      test('leaves another item\'s refusal unshown', () async {
        database.seedRefusal(refusal());
        database.seedRefusal(refusal(itemName: 'Excavator', method: 'day'));

        await dataSource.markRefusalShownByItem('Dumpster — 30 yd', 'job');

        final other = await dataSource.loadRefusalByItem('Excavator', 'day');
        expect(other?.shownAt, isNull);
      });

      test('does nothing when the item has no refusal', () async {
        await dataSource.markRefusalShownByItem('Dumpster — 30 yd', 'job');

        expect(
          await dataSource.loadRefusalByItem('Dumpster — 30 yd', 'job'),
          isNull,
        );
      });
    });

    group('deleteRefusalByItem', () {
      test('forgets the refusal of that item only', () async {
        database.seedRefusal(refusal());
        database.seedRefusal(refusal(itemName: 'Excavator', method: 'day'));

        await dataSource.deleteRefusalByItem('Dumpster — 30 yd', 'job');

        expect(
          await dataSource.loadRefusalByItem('Dumpster — 30 yd', 'job'),
          isNull,
        );
        expect(
          await dataSource.loadRefusalByItem('Excavator', 'day'),
          isNotNull,
        );
      });
    });

    group('watchRefusalByItem', () {
      test('emits null while the server has refused nothing', () async {
        await expectLater(
          dataSource.watchRefusalByItem('Dumpster — 30 yd', 'job'),
          emits(isNull),
        );
      });

      test('emits the refusal when the upload step records one', () async {
        final emissions = expectLater(
          dataSource.watchRefusalByItem('Dumpster — 30 yd', 'job'),
          emitsInOrder([
            isNull,
            isA<YourRateRefusalDto>().having(
              (refusal) => refusal.refusedAmount,
              'refusedAmount',
              450.0,
            ),
          ]),
        );

        database.seedRefusal(refusal());

        await emissions;
      });

      test('emits the shown time once the message was shown', () async {
        database.seedRefusal(refusal());

        final emissions = expectLater(
          dataSource.watchRefusalByItem('Dumpster — 30 yd', 'job'),
          emitsInOrder([
            isA<YourRateRefusalDto>().having(
              (refusal) => refusal.shownAt,
              'shownAt',
              isNull,
            ),
            isA<YourRateRefusalDto>().having(
              (refusal) => refusal.shownAt,
              'shownAt',
              isNotNull,
            ),
          ]),
        );

        await dataSource.markRefusalShownByItem('Dumpster — 30 yd', 'job');

        await emissions;
      });

      test('emits null again once the refusal is forgotten', () async {
        database.seedRefusal(refusal());

        final emissions = expectLater(
          dataSource.watchRefusalByItem('Dumpster — 30 yd', 'job'),
          emitsInOrder([isNotNull, isNull]),
        );

        await dataSource.deleteRefusalByItem('Dumpster — 30 yd', 'job');

        await emissions;
      });
    });

    group('read failure', () {
      test('rethrows so the repository can map it', () async {
        database.getAllError = StateError('disk full');

        await expectLater(
          dataSource.loadRefusalByItem('Dumpster — 30 yd', 'job'),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}

class _RefusalTestModule extends Module {
  final FakeYourRatesDatabase database;
  final FakeClockImpl clock;

  _RefusalTestModule(this.database, this.clock);

  @override
  void binds(Injector i) {
    i.addSingleton<YourRateRefusalDataSource>(
      () => LocalYourRateRefusalDataSource(database: database, clock: clock),
    );
  }
}
