import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
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

void main() {
  group('LastUsedUnitRepository', () {
    late FakeStorageService storage;
    late FakeAuthRepository auth;
    late LastUsedUnitRepository repository;

    setUpAll(() {
      final clock = FakeClockImpl();
      storage = FakeStorageService();
      auth = FakeAuthRepository(clock: clock);
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: clock),
          ),
        ),
      );
      Modular.replaceInstance<StorageService>(storage);
      Modular.replaceInstance<AuthRepository>(auth);
      repository = Modular.get<LastUsedUnitRepository>();
    });

    tearDownAll(Modular.dispose);

    setUp(() {
      storage.reset();
      auth.reset();
      auth.setCurrentCredentials(_credential('account-1'));
    });

    Future<Unit?> lastUnit(CostItemType category, String itemName) async =>
        (await repository.getLastUnits(category)).forItem(itemName);

    Future<void> save(CostItemType category, String itemName, Unit unit) =>
        repository.saveLastUnit(category, itemName, unit);

    test('returns nothing when no unit was saved', () async {
      expect(await lastUnit(CostItemType.material, 'Paint'), isNull);
    });

    test('returns the unit last saved for the material', () async {
      await save(CostItemType.material, 'Paint', Unit.liters);
      await save(CostItemType.material, 'Paint', Unit.gallons);

      expect(await lastUnit(CostItemType.material, 'Paint'), Unit.gallons);
    });

    test('remembers each material on its own', () async {
      await save(CostItemType.material, 'Paint', Unit.gallons);
      await save(CostItemType.material, 'Drywall', Unit.sheets);

      expect(await lastUnit(CostItemType.material, 'Paint'), Unit.gallons);
      expect(await lastUnit(CostItemType.material, 'Drywall'), Unit.sheets);
      expect(await lastUnit(CostItemType.material, 'Primer'), isNull);
    });

    test('matches names regardless of capitals and extra spaces', () async {
      await save(CostItemType.material, '  Interior   paint ', Unit.gallons);

      expect(
        await lastUnit(CostItemType.material, 'INTERIOR PAINT'),
        Unit.gallons,
      );
    });

    test('remembers each category on its own', () async {
      await save(CostItemType.material, 'Crew', Unit.liters);
      await save(CostItemType.labor, 'Crew', Unit.hours);

      expect(await lastUnit(CostItemType.material, 'Crew'), Unit.liters);
      expect(await lastUnit(CostItemType.labor, 'Crew'), Unit.hours);
      expect(await lastUnit(CostItemType.equipment, 'Crew'), isNull);
    });

    test('remembers each account on its own', () async {
      await save(CostItemType.material, 'Paint', Unit.liters);
      auth.setCurrentCredentials(_credential('account-2'));

      expect(await lastUnit(CostItemType.material, 'Paint'), isNull);

      await save(CostItemType.material, 'Paint', Unit.rolls);
      auth.setCurrentCredentials(_credential('account-1'));

      expect(await lastUnit(CostItemType.material, 'Paint'), Unit.liters);
    });

    test(
      'saves nothing and returns nothing with no signed-in account',
      () async {
        auth.reset();

        await save(CostItemType.material, 'Paint', Unit.liters);

        expect(await lastUnit(CostItemType.material, 'Paint'), isNull);
        auth.setCurrentCredentials(_credential('account-1'));
        expect(await lastUnit(CostItemType.material, 'Paint'), isNull);
      },
    );

    test('returns nothing when the saved units cannot be read', () async {
      await save(CostItemType.material, 'Paint', Unit.liters);
      storage.shouldThrowOnRead = true;

      expect(await lastUnit(CostItemType.material, 'Paint'), isNull);
    });

    test('returns nothing for a material whose saved unit is no longer a '
        'known unit, and keeps the others', () async {
      const key = 'last_used_units.account-1.material';
      await save(CostItemType.material, 'Paint', Unit.gallons);
      await save(CostItemType.material, 'Drywall', Unit.sheets);
      final saved = await storage.getData<String>(key);
      await storage.saveData<String>(
        key,
        saved!.replaceFirst('"gallons"', '"furlongs"'),
      );

      expect(await lastUnit(CostItemType.material, 'Paint'), isNull);
      expect(await lastUnit(CostItemType.material, 'Drywall'), Unit.sheets);
    });

    test('keeps the previous unit when a save fails', () async {
      await save(CostItemType.material, 'Paint', Unit.liters);
      storage.shouldThrowOnWrite = true;

      await save(CostItemType.material, 'Paint', Unit.bags);
      storage.shouldThrowOnWrite = false;

      expect(await lastUnit(CostItemType.material, 'Paint'), Unit.liters);
    });

    test('starts over when the saved units are damaged', () async {
      await storage.saveData<String>(
        'last_used_units.account-1.material',
        'not json',
      );

      await save(CostItemType.material, 'Paint', Unit.gallons);

      expect(await lastUnit(CostItemType.material, 'Paint'), Unit.gallons);
    });
  });
}
