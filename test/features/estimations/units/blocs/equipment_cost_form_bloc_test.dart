import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('EquipmentCostFormBloc', () {
    late EquipmentCostFormBloc bloc;

    const testEquipmentName = 'Excavator';

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
                (s) => s.equipmentType,
                'equipmentType',
                testEquipmentName,
              )
              .having((s) => s.itemTypeError, 'itemTypeError', isNull)
              .having((s) => s.isItemTypeValid, 'isItemTypeValid', true),
        ],
      );
    });

    // TODO(CA-294): add submit event tests covering happy path, validation guard, and server errors
  });
}
