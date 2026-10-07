import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
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

MaterialCostFormData _dataOf(MaterialCostFormState state) =>
    (state as MaterialCostFormEditing).data;

void main() {
  group('MaterialCostFormBloc', () {
    late MaterialCostFormBloc bloc;
    late FakeStorageService storage;
    late FakeAuthRepository auth;
    late LastUsedUnitRepository lastUsedUnits;

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
      lastUsedUnits = Modular.get<LastUsedUnitRepository>();
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      storage.reset();
      auth.reset();
      auth.setCurrentCredentials(
        UserCredential(
          id: 'account-1',
          email: 'a@example.com',
          metadata: const {},
          createdAt: DateTime(2026),
        ),
      );
      bloc = Modular.get<MaterialCostFormBloc>();
    });

    test('initial state is MaterialCostFormInitial', () {
      expect(bloc.state, isA<MaterialCostFormInitial>());
    });

    group('default unit', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'selects the unit this account used last for materials',
        setUp: () =>
            lastUsedUnits.saveLastUnit(CostItemType.material, Unit.bags),
        build: () => bloc,
        act: (b) => b.add(const MaterialCostFormStarted()),
        verify: (b) => expect(_dataOf(b.state).unit, Unit.bags),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'ignores the unit remembered for another category',
        setUp: () => lastUsedUnits.saveLastUnit(CostItemType.labor, Unit.hours),
        build: () => bloc,
        act: (b) => b.add(const MaterialCostFormStarted()),
        expect: () => <MaterialCostFormState>[],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'leaves the unit empty when none is remembered',
        build: () => bloc,
        act: (b) => b.add(const MaterialCostFormStarted()),
        expect: () => <MaterialCostFormState>[],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'leaves the unit empty when the remembered unit cannot be read',
        setUp: () async {
          await lastUsedUnits.saveLastUnit(CostItemType.material, Unit.bags);
          storage.shouldThrowOnRead = true;
        },
        build: () => bloc,
        act: (b) => b.add(const MaterialCostFormStarted()),
        expect: () => <MaterialCostFormState>[],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'keeps a unit the user already picked',
        setUp: () =>
            lastUsedUnits.saveLastUnit(CostItemType.material, Unit.bags),
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialUnitSelected(Unit.liters))
          ..add(const MaterialCostFormStarted()),
        verify: (b) => expect(_dataOf(b.state).unit, Unit.liters),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'keeps the name already typed',
        setUp: () =>
            lastUsedUnits.saveLastUnit(CostItemType.material, Unit.bags),
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialCostItemTypeChanged('Paint'))
          ..add(const MaterialCostFormStarted()),
        verify: (b) {
          expect(_dataOf(b.state).itemName, 'Paint');
          expect(_dataOf(b.state).unit, Unit.bags);
        },
      );
    });

    group('material name', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'keeps the name as typed',
        build: () => bloc,
        act: (b) => b.add(const MaterialCostItemTypeChanged('Concrete')),
        verify: (b) => expect(_dataOf(b.state).itemName, 'Concrete'),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'treats a blank name as missing, not as an error',
        build: () => bloc,
        act: (b) => b.add(const MaterialCostItemTypeChanged('   ')),
        verify: (b) {
          final data = _dataOf(b.state);
          expect(data.isItemNameValid, isFalse);
          expect(data.fieldErrors, isEmpty);
          expect(
            data.blocker,
            const MaterialFormBlocker(
              MaterialFormField.itemName,
              MaterialBlockerKind.missing,
            ),
          );
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'accepts a name longer than 80 characters',
        build: () => bloc,
        act: (b) => b.add(MaterialCostItemTypeChanged('a' * 120)),
        verify: (b) {
          expect(_dataOf(b.state).itemName.length, 120);
          expect(_dataOf(b.state).isItemNameValid, isTrue);
        },
      );
    });

    group('quantity', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'reads a positive quantity',
        build: () => bloc,
        act: (b) => b.add(const MaterialQuantityUpdated('2.5')),
        verify: (b) {
          expect(_dataOf(b.state).quantity, 2.5);
          expect(_dataOf(b.state).fieldErrors, isEmpty);
        },
      );

      for (final entry in {'0': 0.0, '-3': -3.0}.entries) {
        blocTest<MaterialCostFormBloc, MaterialCostFormState>(
          'flags a quantity of ${entry.key} as not positive',
          build: () => bloc,
          act: (b) => b.add(MaterialQuantityUpdated(entry.key)),
          verify: (b) {
            expect(
              _dataOf(b.state).fieldErrors[MaterialFormField.quantity],
              MaterialFieldError.quantityNotPositive,
            );
            expect(_dataOf(b.state).quantity, entry.value);
          },
        );
      }

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'flags NaN as not positive',
        build: () => bloc,
        act: (b) => b.add(const MaterialQuantityUpdated('NaN')),
        verify: (b) => expect(
          _dataOf(b.state).fieldErrors[MaterialFormField.quantity],
          MaterialFieldError.quantityNotPositive,
        ),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'accepts a quantity just under what the column holds',
        build: () => bloc,
        act: (b) => b.add(const MaterialQuantityUpdated('99999999999999')),
        verify: (b) => expect(_dataOf(b.state).fieldErrors, isEmpty),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'flags a quantity the column cannot hold',
        build: () => bloc,
        act: (b) => b.add(const MaterialQuantityUpdated('100000000000000')),
        verify: (b) => expect(
          _dataOf(b.state).fieldErrors[MaterialFormField.quantity],
          MaterialFieldError.quantityTooLarge,
        ),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'treats an empty or unreadable quantity as missing',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialQuantityUpdated('4'))
          ..add(const MaterialQuantityUpdated('')),
        verify: (b) {
          expect(_dataOf(b.state).quantity, isNull);
          expect(_dataOf(b.state).fieldErrors, isEmpty);
        },
      );
    });

    group('rate', () {
      for (final text in ['0.01', '52', '999999.99']) {
        blocTest<MaterialCostFormBloc, MaterialCostFormState>(
          'accepts a rate of $text',
          build: () => bloc,
          act: (b) => b.add(MaterialRateUpdated(text)),
          verify: (b) {
            expect(_dataOf(b.state).rate, double.parse(text));
            expect(_dataOf(b.state).fieldErrors, isEmpty);
          },
        );
      }

      for (final text in ['0', '0.009', '1000000', '999999.995', '-1', 'NaN']) {
        blocTest<MaterialCostFormBloc, MaterialCostFormState>(
          'flags a rate of $text as out of range',
          build: () => bloc,
          act: (b) => b.add(MaterialRateUpdated(text)),
          verify: (b) => expect(
            _dataOf(b.state).fieldErrors[MaterialFormField.rate],
            MaterialFieldError.rateOutOfRange,
          ),
        );
      }

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'marks a typed rate as the user\'s own, which removes the Sample-rate tag',
        build: () => bloc,
        act: (b) => b.add(const MaterialRateUpdated('52')),
        verify: (b) =>
            expect(_dataOf(b.state).rateStatus, RateStatus.ownRateConfirmed),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'returns to missing when the rate is cleared',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialRateUpdated('52'))
          ..add(const MaterialRateUpdated('')),
        verify: (b) {
          expect(_dataOf(b.state).rate, isNull);
          expect(_dataOf(b.state).rateStatus, RateStatus.missing);
        },
      );
    });

    group('Add enablement', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'stays disabled until name, quantity, unit and rate are all set',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialCostItemTypeChanged('Interior paint'))
          ..add(const MaterialQuantityUpdated('2'))
          ..add(const MaterialRateUpdated('52')),
        verify: (b) {
          expect(_dataOf(b.state).isValid, isFalse);
          expect(
            _dataOf(b.state).blocker,
            const MaterialFormBlocker(
              MaterialFormField.unit,
              MaterialBlockerKind.missing,
            ),
          );
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'enables the instant the fourth value arrives',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialCostItemTypeChanged('Interior paint'))
          ..add(const MaterialQuantityUpdated('2'))
          ..add(const MaterialRateUpdated('52'))
          ..add(const MaterialUnitSelected(Unit.liters)),
        expect: () => [
          isA<MaterialCostFormEditing>().having(
            (s) => s.data.isValid,
            'isValid',
            false,
          ),
          isA<MaterialCostFormEditing>().having(
            (s) => s.data.isValid,
            'isValid',
            false,
          ),
          isA<MaterialCostFormEditing>().having(
            (s) => s.data.isValid,
            'isValid',
            false,
          ),
          isA<MaterialCostFormEditing>()
              .having((s) => s.data.isValid, 'isValid', true)
              .having((s) => s.data.blocker, 'blocker', isNull),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'disables again when a valid value becomes invalid',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialCostItemTypeChanged('Interior paint'))
          ..add(const MaterialQuantityUpdated('2'))
          ..add(const MaterialRateUpdated('52'))
          ..add(const MaterialUnitSelected(Unit.liters))
          ..add(const MaterialQuantityUpdated('0')),
        verify: (b) => expect(_dataOf(b.state).isValid, isFalse),
      );

      final allFields = <MaterialFormField, MaterialCostFormEvent>{
        MaterialFormField.itemName: const MaterialCostItemTypeChanged('Paint'),
        MaterialFormField.quantity: const MaterialQuantityUpdated('2'),
        MaterialFormField.unit: const MaterialUnitSelected(Unit.liters),
        MaterialFormField.rate: const MaterialRateUpdated('52'),
      };
      for (final missing in allFields.keys) {
        blocTest<MaterialCostFormBloc, MaterialCostFormState>(
          'stays disabled when only the ${missing.name} is missing',
          build: () => bloc,
          act: (b) {
            for (final entry in allFields.entries) {
              if (entry.key != missing) b.add(entry.value);
            }
          },
          verify: (b) {
            expect(_dataOf(b.state).isValid, isFalse);
            expect(
              _dataOf(b.state).blocker,
              MaterialFormBlocker(missing, MaterialBlockerKind.missing),
            );
          },
        );
      }

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'reports the first missing field reading top to bottom',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialRateUpdated('52'))
          ..add(const MaterialUnitSelected(Unit.liters)),
        verify: (b) => expect(
          _dataOf(b.state).blocker,
          const MaterialFormBlocker(
            MaterialFormField.itemName,
            MaterialBlockerKind.missing,
          ),
        ),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'reports an invalid value as invalid, not missing',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialCostItemTypeChanged('Interior paint'))
          ..add(const MaterialQuantityUpdated('0')),
        verify: (b) => expect(
          _dataOf(b.state).blocker,
          const MaterialFormBlocker(
            MaterialFormField.quantity,
            MaterialBlockerKind.invalid,
          ),
        ),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'names an invalid rate when everything else is set',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialCostItemTypeChanged('Interior paint'))
          ..add(const MaterialQuantityUpdated('2'))
          ..add(const MaterialUnitSelected(Unit.liters))
          ..add(const MaterialRateUpdated('1000000')),
        verify: (b) => expect(
          _dataOf(b.state).blocker,
          const MaterialFormBlocker(
            MaterialFormField.rate,
            MaterialBlockerKind.invalid,
          ),
        ),
      );
    });

    // TODO(CA-294): add submit event tests covering happy path, validation guard, and server errors
  });
}
