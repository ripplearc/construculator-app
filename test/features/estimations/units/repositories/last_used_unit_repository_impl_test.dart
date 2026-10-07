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

    test('returns nothing when no unit was saved', () async {
      expect(await repository.getLastUnit(CostItemType.material), isNull);
    });

    test('returns the unit last saved for the category', () async {
      await repository.saveLastUnit(CostItemType.material, Unit.liters);
      await repository.saveLastUnit(CostItemType.material, Unit.bags);

      expect(await repository.getLastUnit(CostItemType.material), Unit.bags);
    });

    test('remembers each category on its own', () async {
      await repository.saveLastUnit(CostItemType.material, Unit.liters);
      await repository.saveLastUnit(CostItemType.labor, Unit.hours);

      expect(await repository.getLastUnit(CostItemType.material), Unit.liters);
      expect(await repository.getLastUnit(CostItemType.labor), Unit.hours);
      expect(await repository.getLastUnit(CostItemType.equipment), isNull);
    });

    test('remembers each account on its own', () async {
      await repository.saveLastUnit(CostItemType.material, Unit.liters);
      auth.setCurrentCredentials(_credential('account-2'));

      expect(await repository.getLastUnit(CostItemType.material), isNull);

      await repository.saveLastUnit(CostItemType.material, Unit.rolls);
      auth.setCurrentCredentials(_credential('account-1'));

      expect(await repository.getLastUnit(CostItemType.material), Unit.liters);
    });

    test(
      'saves nothing and returns nothing with no signed-in account',
      () async {
        auth.reset();

        await repository.saveLastUnit(CostItemType.material, Unit.liters);

        expect(await repository.getLastUnit(CostItemType.material), isNull);
        auth.setCurrentCredentials(_credential('account-1'));
        expect(await repository.getLastUnit(CostItemType.material), isNull);
      },
    );

    test('returns nothing when the saved unit cannot be read', () async {
      await repository.saveLastUnit(CostItemType.material, Unit.liters);
      storage.shouldThrowOnRead = true;

      expect(await repository.getLastUnit(CostItemType.material), isNull);
    });

    test('keeps the previous unit when a save fails', () async {
      await repository.saveLastUnit(CostItemType.material, Unit.liters);
      storage.shouldThrowOnWrite = true;

      await repository.saveLastUnit(CostItemType.material, Unit.bags);
      storage.shouldThrowOnWrite = false;

      expect(await repository.getLastUnit(CostItemType.material), Unit.liters);
    });
  });
}
