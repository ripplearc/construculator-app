import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/labour_cost_form_bloc/labour_cost_form_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('LabourCostFormBloc', () {
    late LabourCostFormBloc bloc;

    const testLabourType = 'Bricklayer';

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

    // TODO(CA-294): add submit event tests covering happy path, validation guard, and server errors

    group('LabourCostCalculationMethodChanged', () {
      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits Editing with calculationMethod set to perHour',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const LabourCostCalculationMethodChanged(
            LaborCalculationMethodType.perHour,
          ),
        ),
        expect: () => [
          isA<LabourCostFormEditing>().having(
            (s) => s.calculationMethod,
            'calculationMethod',
            LaborCalculationMethodType.perHour,
          ),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits Editing with null calculationMethod when null is passed',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const LabourCostCalculationMethodChanged(null)),
        expect: () => [
          isA<LabourCostFormEditing>().having(
            (s) => s.calculationMethod,
            'calculationMethod',
            isNull,
          ),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'preserves labourType when calculationMethod changes',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const LabourCostItemTypeChanged(testLabourType))
          ..add(
            const LabourCostCalculationMethodChanged(
              LaborCalculationMethodType.perHour,
            ),
          ),
        expect: () => [
          isA<LabourCostFormEditing>().having(
            (s) => s.labourType,
            'labourType',
            testLabourType,
          ),
          isA<LabourCostFormEditing>()
              .having((s) => s.labourType, 'labourType', testLabourType)
              .having(
                (s) => s.calculationMethod,
                'calculationMethod',
                LaborCalculationMethodType.perHour,
              ),
        ],
      );
    });

    group('LabourCostLaborValueUpdated', () {
      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits Editing with laborValue containing laborHours',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const LabourCostLaborValueUpdated(LaborValue(laborHours: 8.0)),
        ),
        expect: () => [
          isA<LabourCostFormEditing>().having(
            (s) => s.laborValue?.laborHours,
            'laborValue.laborHours',
            8.0,
          ),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits Editing with null laborValue when null is passed',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostLaborValueUpdated(null)),
        expect: () => [
          isA<LabourCostFormEditing>().having(
            (s) => s.laborValue,
            'laborValue',
            isNull,
          ),
        ],
      );
    });

    group('LabourCostCrewSizeUpdated', () {
      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits crewSizeError when crewSize is null',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostCrewSizeUpdated(null)),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.crewSizeError, 'crewSizeError', isNotNull)
              .having((s) => s.isCrewSizeValid, 'isCrewSizeValid', false),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits crewSizeError when crewSize is zero',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostCrewSizeUpdated(0)),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.crewSizeError, 'crewSizeError', isNotNull)
              .having((s) => s.isCrewSizeValid, 'isCrewSizeValid', false),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits crewSizeError when crewSize is negative',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostCrewSizeUpdated(-2)),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.crewSizeError, 'crewSizeError', isNotNull)
              .having((s) => s.isCrewSizeValid, 'isCrewSizeValid', false),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits no error and sets crewSize when value is positive',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostCrewSizeUpdated(2.0)),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.crewSize, 'crewSize', 2.0)
              .having((s) => s.crewSizeError, 'crewSizeError', isNull)
              .having((s) => s.isCrewSizeValid, 'isCrewSizeValid', true),
        ],
      );
    });

    group('LabourCostHourlyRateUpdated', () {
      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits hourlyRateError when value is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostHourlyRateUpdated('')),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.hourlyRateError, 'hourlyRateError', isNotNull)
              .having((s) => s.isHourlyRateValid, 'isHourlyRateValid', false),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits hourlyRateError when value is zero',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostHourlyRateUpdated('0')),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.hourlyRateError, 'hourlyRateError', isNotNull)
              .having((s) => s.isHourlyRateValid, 'isHourlyRateValid', false),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits hourlyRateError when value is negative',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostHourlyRateUpdated('-10')),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.hourlyRateError, 'hourlyRateError', isNotNull)
              .having((s) => s.isHourlyRateValid, 'isHourlyRateValid', false),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits hourlyRateError when value is not a number',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostHourlyRateUpdated('abc')),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.hourlyRateError, 'hourlyRateError', isNotNull)
              .having((s) => s.isHourlyRateValid, 'isHourlyRateValid', false),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'emits no error and sets hourlyRate when value is positive',
        build: () => bloc,
        act: (bloc) => bloc.add(const LabourCostHourlyRateUpdated('100')),
        expect: () => [
          isA<LabourCostFormEditing>()
              .having((s) => s.hourlyRate, 'hourlyRate', 100.0)
              .having((s) => s.hourlyRateError, 'hourlyRateError', isNull)
              .having((s) => s.isHourlyRateValid, 'isHourlyRateValid', true),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'preserves labourType when hourly rate changes',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const LabourCostItemTypeChanged(testLabourType))
          ..add(const LabourCostHourlyRateUpdated('50')),
        expect: () => [
          isA<LabourCostFormEditing>().having(
            (s) => s.labourType,
            'labourType',
            testLabourType,
          ),
          isA<LabourCostFormEditing>()
              .having((s) => s.labourType, 'labourType', testLabourType)
              .having((s) => s.hourlyRate, 'hourlyRate', 50.0)
              .having((s) => s.hourlyRateError, 'hourlyRateError', isNull),
        ],
      );
    });

    group('perHourTotal', () {
      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'returns correct total: hourlyRate × laborHours × crewSize',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            const LabourCostCalculationMethodChanged(
              LaborCalculationMethodType.perHour,
            ),
          )
          ..add(const LabourCostHourlyRateUpdated('100'))
          ..add(
            const LabourCostLaborValueUpdated(LaborValue(laborHours: 8.0)),
          )
          ..add(const LabourCostCrewSizeUpdated(2.0)),
        expect: () => [
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormEditing>().having(
            (s) => s.perHourTotal,
            'perHourTotal',
            1600.0,
          ),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'perHourTotal is 0 when calculationMethod is perDay',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            const LabourCostCalculationMethodChanged(
              LaborCalculationMethodType.perDay,
            ),
          )
          ..add(const LabourCostHourlyRateUpdated('100'))
          ..add(
            const LabourCostLaborValueUpdated(LaborValue(laborHours: 8.0)),
          )
          ..add(const LabourCostCrewSizeUpdated(2.0)),
        expect: () => [
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormEditing>().having(
            (s) => s.perHourTotal,
            'perHourTotal',
            0.0,
          ),
        ],
      );

      blocTest<LabourCostFormBloc, LabourCostFormState>(
        'perHourTotal is 0 when calculationMethod is null',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const LabourCostHourlyRateUpdated('100'))
          ..add(
            const LabourCostLaborValueUpdated(LaborValue(laborHours: 8.0)),
          )
          ..add(const LabourCostCrewSizeUpdated(2.0)),
        expect: () => [
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormEditing>(),
          isA<LabourCostFormEditing>().having(
            (s) => s.perHourTotal,
            'perHourTotal',
            0.0,
          ),
        ],
      );
    });
  });
}
