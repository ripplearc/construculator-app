import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('EquipmentCostFormBloc', () {
    late EquipmentCostFormBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    const testEstimateId = 'test-estimate-123';
    const testEquipmentName = 'Excavator';

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
      bloc = Modular.get<EquipmentCostFormBloc>();
    });

    test('initial state is EquipmentCostFormInitial', () {
      expect(bloc.state, isA<EquipmentCostFormInitial>());
    });

    group('EquipmentCostItemTypeChanged', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Editing with itemTypeError when value is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentCostItemTypeChanged('')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.itemTypeError, 'itemTypeError', isNotNull)
              .having((s) => s.isItemTypeValid, 'isItemTypeValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Editing with no error when value is non-empty',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const EquipmentCostItemTypeChanged(testEquipmentName)),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.equipmentName,
                'equipmentName',
                testEquipmentName,
              )
              .having((s) => s.itemTypeError, 'itemTypeError', isNull)
              .having((s) => s.isItemTypeValid, 'isItemTypeValid', true),
        ],
      );
    });

    group('EquipmentCostFormSubmitted', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Editing with error when submitted with empty equipment name',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const EquipmentCostFormSubmitted(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.itemTypeError,
            'itemTypeError',
            isNotNull,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits [Submitting, Success] when submitted with valid equipment name',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const EquipmentCostItemTypeChanged(testEquipmentName));
          bloc.add(
            const EquipmentCostFormSubmitted(estimateId: testEstimateId),
          );
        },
        expect: () => [
          isA<EquipmentCostFormEditing>(),
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormSuccess>().having(
            (s) => (s.item as EquipmentCostItem).itemName,
            'itemName',
            testEquipmentName,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits [Submitting, Failure] with empty equipmentName when data source throws socket error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) {
          bloc.add(const EquipmentCostItemTypeChanged(testEquipmentName));
          bloc.add(
            const EquipmentCostFormSubmitted(estimateId: testEstimateId),
          );
        },
        expect: () => [
          isA<EquipmentCostFormEditing>(),
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormFailure>().having(
            (s) => s.equipmentName,
            'equipmentName',
            '',
          ),
        ],
      );
    });
  });
}
