import 'package:construculator/features/estimation/data/data_source/interfaces/your_rate_refusal_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/local_your_rate_refusal_data_source.dart';
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

    const userA = 'user-a';
    const userB = 'user-b';
    const companyA = 'company-a';
    const companyB = 'company-b';

    Map<String, Object?> refusal({
      String userId = userA,
      String companyId = companyA,
      String category = 'equipment',
      String itemName = 'Dumpster — 30 yd',
      String? method = 'job',
      double refused = 450.0,
      double? accepted = 400.0,
      String? shownAt,
    }) => {
      'id': YourRateRefusalKey.of(
        userId: userId,
        companyId: companyId,
        category: category,
        itemName: itemName,
        equipmentMethod: method,
      ),
      'user_id': userId,
      'company_id': companyId,
      'category': category,
      'refused_row_id': 'row-1',
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
            await dataSource.loadRefusalByItem(
              userId: userA,
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            isNull,
          );
        },
      );

      test('returns the refused and the accepted amounts', () async {
        database.seedRefusal(refusal());

        final found = await dataSource.loadRefusalByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        expect(found!.refusedAmount, 450.0);
        expect(found.acceptedAmount, 400.0);
        expect(found.shownAt, isNull);
      });

      test(
        'returns a null accepted amount when the server never accepted one',
        () async {
          database.seedRefusal(refusal(accepted: null));

          final found = await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          );

          expect(found!.acceptedAmount, isNull);
        },
      );

      test('matches the name ignoring case and extra spaces', () async {
        database.seedRefusal(refusal());

        final found = await dataSource.loadRefusalByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: '  dumpster —  30 YD ',
          equipmentMethod: 'job',
        );

        expect(found, isNotNull);
      });

      test('keeps another company\'s refusal out of the read', () async {
        database.seedRefusal(refusal(companyId: companyA));

        expect(
          await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyB,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          isNull,
        );
      });

      test(
        'keeps another user\'s refusal of the same company out of the read',
        () async {
          database.seedRefusal(refusal(userId: userA));

          expect(
            await dataSource.loadRefusalByItem(
              userId: userB,
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            isNull,
          );
        },
      );

      test('keeps another category\'s refusal out of the read', () async {
        database.seedRefusal(refusal(category: 'material', method: null));

        expect(
          await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'labor',
            itemName: 'Dumpster — 30 yd',
          ),
          isNull,
        );
      });

      test(
        'keeps one pricing method\'s refusal out of the other method\'s read',
        () async {
          database.seedRefusal(refusal(method: 'job'));

          expect(
            await dataSource.loadRefusalByItem(
              userId: userA,
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'day',
            ),
            isNull,
          );
        },
      );
    });

    group('markRefusalShownByItem', () {
      test('stores when the message was shown', () async {
        database.seedRefusal(refusal());

        await dataSource.markRefusalShownByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        final found = await dataSource.loadRefusalByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );
        expect(found!.shownAt, '2026-10-07T09:00:00.000Z');
      });

      test('leaves another item\'s refusal unshown', () async {
        database.seedRefusal(refusal());
        database.seedRefusal(refusal(itemName: 'Excavator', method: 'day'));

        await dataSource.markRefusalShownByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        final other = await dataSource.loadRefusalByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Excavator',
          equipmentMethod: 'day',
        );
        expect(other!.shownAt, isNull);
      });

      test('does nothing when the item has no refusal', () async {
        await dataSource.markRefusalShownByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        expect(
          await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          isNull,
        );
      });
    });

    group('markRefusalShownByItem for another company', () {
      test('leaves the first company\'s message unshown', () async {
        database.seedRefusal(refusal(companyId: companyA));

        await dataSource.markRefusalShownByItem(
          userId: userA,
          companyId: companyB,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        final found = await dataSource.loadRefusalByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );
        expect(found!.shownAt, isNull);
      });
    });

    group('markRefusalShownByItem for another user of the company', () {
      test('leaves the first user\'s message unshown', () async {
        database.seedRefusal(refusal(userId: userA));

        await dataSource.markRefusalShownByItem(
          userId: userB,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        final found = await dataSource.loadRefusalByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );
        expect(found!.shownAt, isNull);
      });
    });

    group('deleteRefusalByItem', () {
      test('forgets the refusal of that item only', () async {
        database.seedRefusal(refusal());
        database.seedRefusal(refusal(itemName: 'Excavator', method: 'day'));

        await dataSource.deleteRefusalByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        expect(
          await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          isNull,
        );
        expect(
          await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'equipment',
            itemName: 'Excavator',
            equipmentMethod: 'day',
          ),
          isNotNull,
        );
      });

      test('does not forget another company\'s refusal', () async {
        database.seedRefusal(refusal(companyId: companyA));

        await dataSource.deleteRefusalByItem(
          userId: userA,
          companyId: companyB,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        expect(
          await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          isNotNull,
        );
      });
    });

    group('deleteRefusalByItem for another user of the company', () {
      test('does not forget the first user\'s refusal', () async {
        database.seedRefusal(refusal(userId: userA));

        await dataSource.deleteRefusalByItem(
          userId: userB,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        expect(
          await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          isNotNull,
        );
      });
    });

    group('write failure', () {
      test(
        'marking a refusal as shown rethrows when the phone cannot write',
        () async {
          database.seedRefusal(refusal());
          database.executeError = StateError('disk full');

          await expectLater(
            dataSource.markRefusalShownByItem(
              userId: userA,
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            throwsA(isA<StateError>()),
          );
        },
      );

      test(
        'forgetting a refusal rethrows when the phone cannot write',
        () async {
          database.seedRefusal(refusal());
          database.executeError = StateError('disk full');

          await expectLater(
            dataSource.deleteRefusalByItem(
              userId: userA,
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            throwsA(isA<StateError>()),
          );
        },
      );

      test('forgetting an item with no refusal does nothing', () async {
        database.seedRefusal(refusal(itemName: 'Excavator', method: 'day'));

        await dataSource.deleteRefusalByItem(
          userId: userA,
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        expect(
          await dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'equipment',
            itemName: 'Excavator',
            equipmentMethod: 'day',
          ),
          isNotNull,
        );
      });
    });

    group('read failure', () {
      test('rethrows so the repository can map it', () async {
        database.getAllError = StateError('disk full');

        await expectLater(
          dataSource.loadRefusalByItem(
            userId: userA,
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
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
