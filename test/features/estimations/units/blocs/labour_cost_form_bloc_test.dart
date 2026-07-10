import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/labour_cost_form_bloc/labour_cost_form_bloc.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('LabourCostFormBloc', () {
    late LabourCostFormBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    const testEstimateId = 'test-estimate-123';
    const testLabourType = 'Bricklayer';

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
      bloc = Modular.get<LabourCostFormBloc>();
    });

    test('initial state is LabourCostFormInitial', () {
      expect(bloc.state, isA<LabourCostFormInitial>());
    });

    group('LabourCostItemTypeChanged', () {
      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits Editing with itemTypeError when value is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostItemTypeChanged('')),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.itemTypeError, 'itemTypeError', isNotNull)
              .having((s) => s.isItemTypeValid, 'isItemTypeValid', false),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits Editing with no error when value is non-empty',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const LabourCostItemTypeChanged(testLabourType)),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.labourType, 'labourType', testLabourType)
              .having((s) => s.itemTypeError, 'itemTypeError', isNull)
              .having((s) => s.isItemTypeValid, 'isItemTypeValid', true),
        ],
      );
    });

    group('LabourCostFormSubmitted', () {
      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits Editing with error when submitted with empty labour type',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const LabourCostFormSubmitted(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<LabourCostFormEditing>().having(
            (s) => s.itemTypeError,
            'itemTypeError',
            isNotNull,
          ),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits [Submitting, Success] when submitted with valid labour type',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const LabourCostItemTypeChanged(testLabourType));
          bloc.add(
            const LabourCostFormSubmitted(estimateId: testEstimateId),
          );
        },
        expect: () => [
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormSubmitting>(),
          isA<LabourCostFormSuccess>().having(
            (s) => (s.item as LaborCostItem).itemName,
            'itemName',
            testLabourType,
          ),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits [Submitting, Failure] with empty labourType when data source throws socket error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) {
          bloc.add(const LabourCostItemTypeChanged(testLabourType));
          bloc.add(
            const LabourCostFormSubmitted(estimateId: testEstimateId),
          );
        },
        expect: () => [
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormSubmitting>(),
          isA<LabourCostFormFailure>().having(
            (s) => s.labourType,
            'labourType',
            '',
          ),
        ],
      );
    });
  });
}
