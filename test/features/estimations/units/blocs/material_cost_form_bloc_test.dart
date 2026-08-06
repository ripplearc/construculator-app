import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
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

    group('MaterialCostItemUnitChanged', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits Editing with unitError when unit is null',
        build: () => bloc,
        act: (bloc) => bloc.add(const MaterialCostItemUnitChanged(null)),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.unitError, 'unitError', isNotNull)
              .having((s) => s.isUnitValid, 'isUnitValid', false),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits Editing with no unitError when a valid unit is provided',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const MaterialCostItemUnitChanged(Unit.pieces)),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.selectedUnit, 'selectedUnit', Unit.pieces)
              .having((s) => s.unitError, 'unitError', isNull)
              .having((s) => s.isUnitValid, 'isUnitValid', true),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'selectedUnit reflects the emitted unit value',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const MaterialCostItemUnitChanged(Unit.kilograms)),
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.selectedUnit, 'selectedUnit', Unit.kilograms),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'preserves existing materialType when unit changes',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const MaterialCostItemTypeChanged(testMaterialType));
          bloc.add(const MaterialCostItemUnitChanged(Unit.meters));
        },
        expect: () => [
          isA<MaterialCostFormEditing>()
              .having((s) => s.materialType, 'materialType', testMaterialType),
          isA<MaterialCostFormEditing>()
              .having((s) => s.materialType, 'materialType', testMaterialType)
              .having((s) => s.selectedUnit, 'selectedUnit', Unit.meters),
        ],
      );
    });

    // TODO(CA-294): add submit event tests covering happy path, validation guard, and server errors
  });
}
