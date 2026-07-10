import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('MaterialCostFormBloc', () {
    late MaterialCostFormBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    const testEstimateId = 'test-estimate-123';
    const testMaterialType = 'Concrete';

    setUpAll(() {
      final bootstrap = FakeAppBootstrapFactory.create(
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      );
      Modular.init(EstimationModule(bootstrap));
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
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

    group('MaterialCostFormSubmitted', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits Editing with error when submitted with empty material type',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const MaterialCostFormSubmitted(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<MaterialCostFormEditing>().having(
            (s) => s.itemTypeError,
            'itemTypeError',
            isNotNull,
          ),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits [Submitting, Success] when submitted with valid material type',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const MaterialCostItemTypeChanged(testMaterialType));
          bloc.add(
            const MaterialCostFormSubmitted(estimateId: testEstimateId),
          );
        },
        expect: () => [
          isA<MaterialCostFormEditing>(),
          isA<MaterialCostFormSubmitting>(),
          isA<MaterialCostFormSuccess>().having(
            (s) => (s.item as MaterialCostItem).itemName,
            'itemName',
            testMaterialType,
          ),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'emits [Submitting, Failure] with empty materialType when data source throws socket error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) {
          bloc.add(const MaterialCostItemTypeChanged(testMaterialType));
          bloc.add(
            const MaterialCostFormSubmitted(estimateId: testEstimateId),
          );
        },
        expect: () => [
          isA<MaterialCostFormEditing>(),
          isA<MaterialCostFormSubmitting>(),
          isA<MaterialCostFormFailure>().having(
            (s) => s.materialType,
            'materialType',
            '',
          ),
        ],
      );
    });
  });
}
