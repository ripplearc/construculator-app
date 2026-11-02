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
      String? entryLabel,
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
      'entry_label': entryLabel,
      'refused_amount': refused,
      'accepted_amount': accepted,
      'shown_at': shownAt,
    };

    Map<String, Object?> rateRow({
      required double amount,
      String? entryLabel,
      String itemName = 'Dumpster — 30 yd',
    }) => {
      'id': 'rate-${entryLabel ?? 'plain'}-$amount',
      'company_id': companyA,
      'category': 'equipment',
      'item_name': itemName,
      'equipment_method': 'job',
      'entry_label': entryLabel,
      'rate_amount': amount,
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

    group('watchRefusalByItem', () {
      test('emits null while the server has refused nothing', () async {
        await expectLater(
          dataSource.watchRefusalByItem(
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          emits(isNull),
        );
      });

      test('emits the refusal when the upload step records one', () async {
        final emissions = expectLater(
          dataSource.watchRefusalByItem(
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
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
          dataSource.watchRefusalByItem(
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
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

        await dataSource.markRefusalShownByItem(
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        await emissions;
      });

      test('emits null while the phone holds a newer price', () async {
        database.seedRefusal(refusal());
        database.seedRow(rateRow(amount: 460.0));

        await expectLater(
          dataSource.watchRefusalByItem(
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          emits(isNull),
        );
      });

      test(
        'emits null when a newer price syncs down after the refusal',
        () async {
          database.seedRefusal(refusal());

          final emissions = expectLater(
            dataSource.watchRefusalByItem(
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            emitsInOrder([isNotNull, isNull]),
          );

          database.seedRow(rateRow(amount: 460.0));

          await emissions;
        },
      );

      test(
        'emits null when the newer price is saved under another spelling of the name',
        () async {
          database.seedRefusal(refusal(itemName: 'dumpster — 30 yd'));
          database.seedRow(
            rateRow(amount: 460.0, itemName: ' Dumpster —  30 YD '),
          );

          await expectLater(
            dataSource.watchRefusalByItem(
              companyId: companyA,
              category: 'equipment',
              itemName: 'dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            emits(isNull),
          );
        },
      );

      test(
        'emits null when the newer price has the label in other capitals',
        () async {
          database.seedRefusal(refusal(entryLabel: 'Weekend'));
          database.seedRow(rateRow(amount: 460.0, entryLabel: ' weekend  '));

          await expectLater(
            dataSource.watchRefusalByItem(
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            emits(isNull),
          );
        },
      );

      test(
        'keeps emitting while the phone still holds the refused price',
        () async {
          database.seedRefusal(refusal());
          database.seedRow(rateRow(amount: 450.0));

          await expectLater(
            dataSource.watchRefusalByItem(
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            emits(isNotNull),
          );
        },
      );

      test(
        'emits null when one of several rows holds the newer price',
        () async {
          database.seedRefusal(refusal());
          database.seedRow(rateRow(amount: 999.0, entryLabel: 'Weekend'));
          database.seedRow(rateRow(amount: 460.0));

          await expectLater(
            dataSource.watchRefusalByItem(
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            emits(isNull),
          );
        },
      );

      test(
        'keeps emitting when only a row of another item holds another price',
        () async {
          database.seedRefusal(refusal());
          database.seedRow(rateRow(amount: 999.0, itemName: 'Excavator'));

          await expectLater(
            dataSource.watchRefusalByItem(
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            emits(isNotNull),
          );
        },
      );

      test('keeps emitting while the phone holds the accepted price', () async {
        database.seedRefusal(refusal());
        database.seedRow(rateRow(amount: 400.0));

        await expectLater(
          dataSource.watchRefusalByItem(
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          emits(isNotNull),
        );
      });

      test(
        'keeps emitting when only another label holds another price',
        () async {
          database.seedRefusal(refusal());
          database.seedRow(rateRow(amount: 999.0, entryLabel: 'Weekend'));

          await expectLater(
            dataSource.watchRefusalByItem(
              companyId: companyA,
              category: 'equipment',
              itemName: 'Dumpster — 30 yd',
              equipmentMethod: 'job',
            ),
            emits(isNotNull),
          );
        },
      );

      test('does not emit another company\'s refusal', () async {
        database.seedRefusal(refusal(companyId: companyA));

        await expectLater(
          dataSource.watchRefusalByItem(
            companyId: companyB,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          emits(isNull),
        );
      });

      test('emits null again once the refusal is forgotten', () async {
        database.seedRefusal(refusal());

        final emissions = expectLater(
          dataSource.watchRefusalByItem(
            companyId: companyA,
            category: 'equipment',
            itemName: 'Dumpster — 30 yd',
            equipmentMethod: 'job',
          ),
          emitsInOrder([isNotNull, isNull]),
        );

        await dataSource.deleteRefusalByItem(
          companyId: companyA,
          category: 'equipment',
          itemName: 'Dumpster — 30 yd',
          equipmentMethod: 'job',
        );

        await emissions;
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
