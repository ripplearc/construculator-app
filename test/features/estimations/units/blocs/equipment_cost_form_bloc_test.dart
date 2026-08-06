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

    const testEquipmentType = 'Excavator';

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
            bloc.add(const EquipmentCostItemTypeChanged(testEquipmentType)),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.equipmentType,
                'equipmentType',
                testEquipmentType,
              )
              .having((s) => s.itemTypeError, 'itemTypeError', isNull)
              .having((s) => s.isItemTypeValid, 'isItemTypeValid', true),
        ],
      );
    });

    group('EquipmentCostUnitPriceChanged', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits unitPriceError when value is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentCostUnitPriceChanged('')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.unitPriceError, 'unitPriceError', isNotNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits unitPriceError when value is zero',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentCostUnitPriceChanged('0')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.unitPriceError, 'unitPriceError', isNotNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits unitPriceError when value is negative',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentCostUnitPriceChanged('-5')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.unitPriceError, 'unitPriceError', isNotNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits unitPriceError when value is not a number',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentCostUnitPriceChanged('abc')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.unitPriceError, 'unitPriceError', isNotNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits no error and sets unitPrice when value is positive',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const EquipmentCostUnitPriceChanged('200.5')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.unitPrice, 'unitPrice', 200.5)
              .having((s) => s.unitPriceError, 'unitPriceError', isNull)
              .having((s) => s.isUnitPriceValid, 'isUnitPriceValid', true),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'preserves equipmentType when unit price changes',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentCostItemTypeChanged(testEquipmentName))
          ..add(const EquipmentCostUnitPriceChanged('100')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.equipmentType,
                'equipmentType',
                testEquipmentName,
              ),
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.equipmentType,
                'equipmentType',
                testEquipmentName,
              )
              .having((s) => s.unitPrice, 'unitPrice', 100.0)
              .having((s) => s.unitPriceError, 'unitPriceError', isNull),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'isValid is false when only equipment name is set',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const EquipmentCostItemTypeChanged(testEquipmentName)),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'isValid is true when equipment name and unit price are both valid',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentCostItemTypeChanged(testEquipmentName))
          ..add(const EquipmentCostUnitPriceChanged('75')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.isValid, 'isValid', false),
          isA<EquipmentCostFormEditing>()
              .having((s) => s.isValid, 'isValid', true),
        ],
      );
    });

    // TODO(CA-294): add submit event tests covering happy path, validation guard, and server errors
  });
}
