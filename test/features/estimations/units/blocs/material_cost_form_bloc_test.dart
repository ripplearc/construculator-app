import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
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

    setUpAll(() {
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          ),
        ),
      );
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      bloc = Modular.get<MaterialCostFormBloc>();
    });

    test('initial state is MaterialCostFormInitial', () {
      expect(bloc.state, isA<MaterialCostFormInitial>());
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
          isA<MaterialCostFormEditing>().having(
            (s) => s.data.isValid,
            'isValid',
            true,
          ),
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
          verify: (b) => expect(_dataOf(b.state).isValid, isFalse),
        );
      }

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'stays disabled when the rate is out of range and the rest is set',
        build: () => bloc,
        act: (b) => b
          ..add(const MaterialCostItemTypeChanged('Interior paint'))
          ..add(const MaterialQuantityUpdated('2'))
          ..add(const MaterialUnitSelected(Unit.liters))
          ..add(const MaterialRateUpdated('1000000')),
        verify: (b) => expect(_dataOf(b.state).isValid, isFalse),
      );
    });

    // TODO(CA-294): add submit event tests covering happy path, validation guard, and server errors
  });
}
