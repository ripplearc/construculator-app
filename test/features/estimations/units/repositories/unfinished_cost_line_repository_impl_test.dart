import 'dart:convert';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/unfinished_cost_line.dart';
import 'package:construculator/features/estimation/domain/repositories/unfinished_cost_line_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

UserCredential _credential(String id) => UserCredential(
  id: id,
  email: '$id@example.com',
  metadata: const {},
  createdAt: DateTime(2026),
);

final _openedAt = DateTime(2026, 11, 10, 9);

UnfinishedCostLine _line({
  String itemName = 'Interior paint',
  String? costItemId,
  DateTime? updatedAt,
}) => UnfinishedCostLine(
  category: CostItemType.material,
  estimateId: 'estimate-1',
  costItemId: costItemId,
  itemName: itemName,
  quantity: 12,
  unit: Unit.liters,
  rate: 14.3,
  wastePercent: 10,
  note: 'Two coats',
  updatedAt: updatedAt ?? _openedAt,
);

void main() {
  group('UnfinishedCostLineRepository', () {
    const key = 'unfinished_cost_line.account-1';
    late FakeStorageService storage;
    late FakeAuthRepository auth;
    late UnfinishedCostLineRepository repository;

    setUp(() {
      final clock = FakeClockImpl();
      storage = FakeStorageService();
      auth = FakeAuthRepository(clock: clock)
        ..setCurrentCredentials(_credential('account-1'));
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: clock),
          ),
        ),
      );
      addTearDown(Modular.destroy);
      Modular.replaceInstance<StorageService>(storage);
      Modular.replaceInstance<AuthRepository>(auth);
      repository = Modular.get<UnfinishedCostLineRepository>();
    });

    test('returns nothing when no line was saved', () async {
      expect(await repository.read(), isNull);
    });

    test('returns every field of the saved line', () async {
      await repository.save(_line(costItemId: 'item-7'));

      final line = await repository.read();

      expect(line, _line(costItemId: 'item-7'));
      expect(
        line,
        _lineWith('isChangeToSavedLine', (l) => l.isChangeToSavedLine, isTrue),
      );
    });

    test('reads a line with only a category and an estimate', () async {
      await repository.save(
        UnfinishedCostLine(
          category: CostItemType.labor,
          estimateId: 'estimate-2',
          updatedAt: _openedAt,
        ),
      );

      final line = await repository.read();

      expect(
        line,
        _lineWith('category', (l) => l.category, CostItemType.labor),
      );
      expect(line, _lineWith('itemName', (l) => l.itemName, ''));
      expect(line, _lineWith('quantity', (l) => l.quantity, isNull));
      expect(line, _lineWith('unit', (l) => l.unit, isNull));
      expect(
        line,
        _lineWith('isChangeToSavedLine', (l) => l.isChangeToSavedLine, isFalse),
      );
    });

    test('a newer line replaces the older one', () async {
      await repository.save(_line(itemName: 'Primer'));
      await repository.save(_line(itemName: 'Interior paint'));

      expect(
        (await repository.read()),
        _lineWith('itemName', (l) => l.itemName, 'Interior paint'),
      );
    });

    test('remove leaves no line', () async {
      await repository.save(_line());

      await repository.remove();

      expect(await repository.read(), isNull);
      expect(storage.valueOf(key), isNull);
    });

    test('keeps a line apart for each account', () async {
      await repository.save(_line(itemName: 'Primer'));
      auth.setCurrentCredentials(_credential('account-2'));

      expect(await repository.read(), isNull);

      await repository.save(_line(itemName: 'Tile'));
      auth.setCurrentCredentials(_credential('account-1'));

      expect(
        (await repository.read()),
        _lineWith('itemName', (l) => l.itemName, 'Primer'),
      );
    });

    test('saves nothing with no signed-in account', () async {
      auth.reset();

      await repository.save(_line());

      expect(await repository.read(), isNull);
      auth.setCurrentCredentials(_credential('account-1'));
      expect(await repository.read(), isNull);
    });

    test('returns nothing when the line cannot be read', () async {
      await repository.save(_line());
      storage.shouldThrowOnRead = true;

      expect(await repository.read(), isNull);
    });

    test('keeps the previous line when a save fails', () async {
      await repository.save(_line(itemName: 'Primer'));
      storage.shouldThrowOnWrite = true;

      await repository.save(_line(itemName: 'Tile'));
      storage.shouldThrowOnWrite = false;

      expect(
        (await repository.read()),
        _lineWith('itemName', (l) => l.itemName, 'Primer'),
      );
    });

    for (final (name, stored) in [
      ('is not JSON', 'not json'),
      ('is not an object', '[1, 2]'),
      ('has an unknown category', _storedWith({'category': 'tools'})),
      ('has no estimate', _storedWith({'estimateId': null})),
      ('has no change time', _storedWith({'updatedAt': 'yesterday'})),
    ]) {
      test('returns nothing when the stored line $name', () async {
        await storage.saveData<String>(key, stored);

        expect(await repository.read(), isNull);
      });
    }

    test('reads an unknown unit as no unit', () async {
      await storage.saveData<String>(key, _storedWith({'unit': 'furlongs'}));

      final line = await repository.read();

      expect(line, _lineWith('unit', (l) => l.unit, isNull));
      expect(line, _lineWith('itemName', (l) => l.itemName, 'Interior paint'));
    });
  });
}

String _storedWith(Map<String, Object?> changes) =>
    jsonEncode({..._line().toJson(), ...changes});

Matcher _lineWith(
  String name,
  Object? Function(UnfinishedCostLine line) field,
  Object? value,
) => isA<UnfinishedCostLine>().having(field, name, value);
