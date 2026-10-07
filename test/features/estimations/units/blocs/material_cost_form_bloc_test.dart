import 'dart:async';

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
    late FakeSupabaseWrapper fakeSupabase;
    late FakeStorageService storage;
    late FakeAuthRepository auth;
    late LastUsedUnitRepository lastUsedUnits;

    setUpAll(() {
      final clock = FakeClockImpl();
      fakeSupabase = FakeSupabaseWrapper(clock: clock);
      storage = FakeStorageService();
      auth = FakeAuthRepository(clock: clock);
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
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
      fakeSupabase.reset();
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

    group('submit', () {
      const estimateId = 'estimate-1';
      const filledEvents = <MaterialCostFormEvent>[
        MaterialCostItemTypeChanged('  Interior paint '),
        MaterialQuantityUpdated('7'),
        MaterialUnitSelected(Unit.liters),
        MaterialRateUpdated('2.55'),
      ];

      Map<String, dynamic> insertedRow() =>
          fakeSupabase.getMethodCallsFor('insert').single['data']
              as Map<String, dynamic>;

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'saves a valid line and reports success',
        build: () => bloc,
        act: (b) {
          filledEvents.forEach(b.add);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
        },
        skip: 4,
        expect: () => [
          isA<MaterialCostFormSubmitting>(),
          isA<MaterialCostFormSuccess>().having(
            (s) => s.createdItem.itemName,
            'itemName',
            'Interior paint',
          ),
        ],
        verify: (_) {
          final row = insertedRow();
          expect(row['estimate_id'], estimateId);
          expect(row['item_name'], 'Interior paint');
          expect(row['item_type'], 'material');
          expect(row['quantity'], 7.0);
          expect(row['unit_measurement'], 'liters');
          expect(row['unit_price'], 2.55);
          expect(row['item_total_cost'], 17.85);
          expect(row['calculation'], {'unit_price': 2.55, 'quantity': 7.0});
          expect(row['rate_status'], 'own_rate_confirmed');
          expect(row['quantity_provenance'], 'manual');
          expect(row['currency'], 'USD');
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'rounds the line total to the cent',
        build: () => bloc,
        act: (b) {
          b
            ..add(const MaterialCostItemTypeChanged('Nails'))
            ..add(const MaterialQuantityUpdated('3'))
            ..add(const MaterialUnitSelected(Unit.boxes))
            ..add(const MaterialRateUpdated('0.335'))
            ..add(const MaterialCostFormSubmitted(estimateId: estimateId));
        },
        verify: (_) => expect(insertedRow()['item_total_cost'], 1.01),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'remembers the unit as the last one used for materials',
        build: () => bloc,
        act: (b) {
          filledEvents.forEach(b.add);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
        },
        verify: (_) async => expect(
          await lastUsedUnits.getLastUnit(CostItemType.material),
          Unit.liters,
        ),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'saves nothing and stays on the form when a value is missing',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialCostItemTypeChanged('Paint'))
          ..add(const MaterialCostFormSubmitted(estimateId: estimateId)),
        verify: (b) {
          expect(b.state, isA<MaterialCostFormEditing>());
          expect(fakeSupabase.getMethodCallsFor('insert'), isEmpty);
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'keeps every value and the last unit when saving fails',
        setUp: () => fakeSupabase.shouldThrowOnInsert = true,
        build: () => bloc,
        act: (b) {
          filledEvents.forEach(b.add);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
        },
        verify: (b) async {
          final failure = b.state as MaterialCostFormFailure;
          expect(failure.data.itemName, '  Interior paint ');
          expect(failure.data.quantity, 7);
          expect(failure.data.unit, Unit.liters);
          expect(failure.data.rate, 2.55);
          expect(
            await lastUsedUnits.getLastUnit(CostItemType.material),
            isNull,
          );
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'saves on a second try after a failure',
        setUp: () => fakeSupabase.shouldThrowOnInsert = true,
        build: () => bloc,
        act: (b) async {
          filledEvents.forEach(b.add);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
          await b.stream.firstWhere((s) => s is MaterialCostFormFailure);
          fakeSupabase.shouldThrowOnInsert = false;
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
        },
        verify: (b) => expect(b.state, isA<MaterialCostFormSuccess>()),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'saves once when Add is tapped twice while the first save runs',
        setUp: () {
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => bloc,
        act: (b) async {
          filledEvents.forEach(b.add);
          b
            ..add(const MaterialCostFormSubmitted(estimateId: estimateId))
            ..add(const MaterialCostFormSubmitted(estimateId: estimateId));
          await b.stream.firstWhere((s) => s is MaterialCostFormSubmitting);
          fakeSupabase.completer!.complete();
          await b.stream.firstWhere((s) => s is MaterialCostFormSuccess);
        },
        verify: (_) =>
            expect(fakeSupabase.getMethodCallsFor('insert'), hasLength(1)),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'ignores edits made while the save is in flight, so the saved line and '
        'the form stay the same',
        setUp: () {
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => bloc,
        act: (b) async {
          filledEvents.forEach(b.add);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
          await b.stream.firstWhere((s) => s is MaterialCostFormSubmitting);
          b
            ..add(const MaterialCostItemTypeChanged('Other name'))
            ..add(const MaterialQuantityUpdated('99'))
            ..add(const MaterialRateUpdated('1'))
            ..add(const MaterialUnitSelected(Unit.bags))
            ..add(const MaterialCostFormSubmitted(estimateId: estimateId));
          fakeSupabase.completer!.complete();
          await b.stream.firstWhere((s) => s is MaterialCostFormSuccess);
        },
        verify: (b) {
          final data = (b.state as MaterialCostFormSuccess).data;
          expect(data.itemName, '  Interior paint ');
          expect(data.quantity, 7);
          expect(data.rate, 2.55);
          expect(data.unit, Unit.liters);
          expect(fakeSupabase.getMethodCallsFor('insert'), hasLength(1));
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits nothing for an edit made while the save is in flight',
        setUp: () {
          fakeSupabase.shouldDelayOperations = true;
          fakeSupabase.completer = Completer<void>();
        },
        build: () => bloc,
        act: (b) async {
          filledEvents.forEach(b.add);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
          await b.stream.firstWhere((s) => s is MaterialCostFormSubmitting);
          b.add(const MaterialCostItemTypeChanged('Other name'));
          fakeSupabase.completer!.complete();
          await b.stream.firstWhere((s) => s is MaterialCostFormSuccess);
        },
        skip: 4,
        expect: () => [
          isA<MaterialCostFormSubmitting>(),
          isA<MaterialCostFormSuccess>(),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'ignores edits after the line was saved',
        build: () => bloc,
        act: (b) async {
          filledEvents.forEach(b.add);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
          await b.stream.firstWhere((s) => s is MaterialCostFormSuccess);
          b.add(const MaterialCostItemTypeChanged('Other name'));
        },
        verify: (b) {
          expect(b.state, isA<MaterialCostFormSuccess>());
          expect(
            (b.state as MaterialCostFormSuccess).data.itemName,
            '  Interior paint ',
          );
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'does not save again after it succeeded',
        build: () => bloc,
        act: (b) async {
          filledEvents.forEach(b.add);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
          await b.stream.firstWhere((s) => s is MaterialCostFormSuccess);
          b.add(const MaterialCostFormSubmitted(estimateId: estimateId));
        },
        verify: (_) =>
            expect(fakeSupabase.getMethodCallsFor('insert'), hasLength(1)),
      );
    });

    group('line total', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'is zero until both quantity and rate are set',
        build: () => bloc,
        act: (b) => b.add(const MaterialQuantityUpdated('3')),
        verify: (b) => expect(_dataOf(b.state).lineTotal, 0),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'is quantity times rate rounded to the cent',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialQuantityUpdated('3'))
          ..add(const MaterialRateUpdated('0.335')),
        verify: (b) => expect(_dataOf(b.state).lineTotal, 1.01),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'is zero when a value is not a finite number',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialQuantityUpdated('Infinity'))
          ..add(const MaterialRateUpdated('2')),
        verify: (b) => expect(_dataOf(b.state).lineTotal, 0),
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
