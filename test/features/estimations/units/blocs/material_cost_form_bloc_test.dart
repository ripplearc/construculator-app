import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('MaterialCostFormBloc', () {
    late MaterialCostFormBloc bloc;

    const testMaterialType = 'Concrete';

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

    group('MaterialCostItemTypeChanged', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits Editing with itemTypeError when value is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const MaterialCostItemTypeChanged('')),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.itemTypeError, 'itemTypeError', isNotNull)
              .having((s) => s.isItemTypeValid, 'isItemTypeValid', false),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits Editing with no error when value is non-empty',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const MaterialCostItemTypeChanged(testMaterialType)),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.materialType, 'materialType', testMaterialType)
              .having((s) => s.itemTypeError, 'itemTypeError', isNull)
              .having((s) => s.isItemTypeValid, 'isItemTypeValid', true),
        ],
      );
    });

    group('MaterialCostUnitPriceChanged', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits unitPriceError when value is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const MaterialCostUnitPriceChanged('')),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.unitPriceError, 'unitPriceError', isNotNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', false),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits unitPriceError when value is zero',
        build: () => bloc,
        act: (bloc) => bloc.add(const MaterialCostUnitPriceChanged('0')),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.unitPriceError, 'unitPriceError', isNotNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', false),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits unitPriceError when value is negative',
        build: () => bloc,
        act: (bloc) => bloc.add(const MaterialCostUnitPriceChanged('-5')),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.unitPriceError, 'unitPriceError', isNotNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', false),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits unitPriceError when value is not a number',
        build: () => bloc,
        act: (bloc) => bloc.add(const MaterialCostUnitPriceChanged('abc')),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.unitPriceError, 'unitPriceError', isNotNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', false),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits no error and sets unitPrice when value is positive',
        build: () => bloc,
        act: (bloc) => bloc.add(const MaterialCostUnitPriceChanged('150.5')),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.unitPrice, 'unitPrice', 150.5)
              .having((s) => s.unitPriceError, 'unitPriceError', isNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', true),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'preserves materialType when unit price changes',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const MaterialCostItemTypeChanged(testMaterialType))
          ..add(const MaterialCostUnitPriceChanged('100')),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.materialType, 'materialType', testMaterialType),
          isA<MaterialCostFormEditing>()
              .having((s) => s.materialType, 'materialType', testMaterialType)
              .having((s) => s.unitPrice, 'unitPrice', 100.0)
              .having((s) => s.unitPriceError, 'unitPriceError', isNull),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'isValid is false when only item type is set',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const MaterialCostItemTypeChanged(testMaterialType)),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.isValid, 'isValid', false),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'isValid is true when item type and unit price are both valid',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const MaterialCostItemTypeChanged(testMaterialType))
          ..add(const MaterialCostUnitPriceChanged('75')),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.isValid, 'isValid', false),
          isA<MaterialCostFormEditing>()
              .having((s) => s.isValid, 'isValid', true),
        ],
      );
    });

    // TODO(CA-294): add submit event tests covering happy path, validation guard, and server errors
  });
}
