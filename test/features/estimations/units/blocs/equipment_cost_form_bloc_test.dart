import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
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

    const testEquipmentType = 'Excavator';
    const testEstimateId = 'estimate-123';

    setUpAll(() {
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          ),
        ),
      );
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

    tearDown(() {
      bloc.close();
    });

    test('initial state is EquipmentCostFormInitial', () {
      expect(bloc.state, isA<EquipmentCostFormInitial>());
    });

    group('EquipmentCostItemTypeChanged', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Editing with no red error but isItemTypeValid false when '
        'value is empty (empty fields never show a red error)',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentCostItemTypeChanged('')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.itemTypeError, 'itemTypeError', isNull)
              .having((s) => s.data.isItemTypeValid, 'isItemTypeValid', false)
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Editing with no item type error when value is non-empty',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const EquipmentCostItemTypeChanged(testEquipmentType)),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.equipmentType,
                'equipmentType',
                testEquipmentType,
              )
              .having((s) => s.itemTypeError, 'itemTypeError', isNull)
              .having((s) => s.data.isItemTypeValid, 'isItemTypeValid', true),
        ],
      );
    });

    group('EquipmentMethodSwitchedEvent', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'preserves equipmentType and deliveryFee when switching Day -> Job',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(const EquipmentDurationUpdatedEvent('5'))
            ..add(const EquipmentRateUpdatedEvent('100'))
            ..add(const EquipmentDeliveryFeeUpdatedEvent('20'))
            ..add(
              const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job),
            );
        },
        skip: 4,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.method,
                'method',
                EquipmentPricingMethod.job,
              )
              .having(
                (s) => s.data.equipmentType,
                'equipmentType',
                testEquipmentType,
              )
              .having((s) => s.data.duration, 'duration', 5)
              .having((s) => s.data.dailyRate, 'dailyRate', 100)
              .having((s) => s.data.deliveryFee, 'deliveryFee', 20)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.missing,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'preserves the job amount when switching back Job -> Day',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(
              const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job),
            )
            ..add(const EquipmentRateUpdatedEvent('500'))
            ..add(
              const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.day),
            );
        },
        skip: 2,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.method,
                'method',
                EquipmentPricingMethod.day,
              )
              .having((s) => s.data.jobAmount, 'jobAmount', 500)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.missing,
              ),
        ],
      );
    });

    group('EquipmentRateUpdatedEvent — rateStatus', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'sets rateStatus to ownRateUnconfirmed (not confirmed) once a '
        'manually typed rate parses',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentRateUpdatedEvent('100')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.dailyRate, 'dailyRate', 100)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateUnconfirmed,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'sets rateStatus back to missing when the rate is cleared',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentRateUpdatedEvent('100'))
          ..add(const EquipmentRateUpdatedEvent('')),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.dailyRate, 'dailyRate', isNull)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.missing,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'sets rateStatus to ownRateUnconfirmed for a manually typed job '
        'amount',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job))
          ..add(const EquipmentRateUpdatedEvent('500')),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.jobAmount, 'jobAmount', 500)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateUnconfirmed,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'does not upgrade a typed, unconfirmed rate to ownRateConfirmed when '
        'switching methods and back',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentRateUpdatedEvent('100')) // dailyRate typed
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job))
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.day)),
        skip: 2,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.dailyRate, 'dailyRate', 100)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateUnconfirmed,
              ),
        ],
      );
    });

    group('EquipmentDurationUpdatedEvent', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blocks submission with no red error when duration is blank (empty '
        'fields never show a red error)',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDurationUpdatedEvent('')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.duration, 'duration', isNull)
              .having(
                (s) => s.data.fieldErrors['duration'],
                'duration error',
                isNull,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blocks submission with a field error when duration is zero '
        '(entered but invalid, unlike a blank field)',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDurationUpdatedEvent('0')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.fieldErrors['duration'],
                'duration error',
                isNotNull,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blocks submission with a field error when duration is negative',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDurationUpdatedEvent('-1')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.fieldErrors['duration'],
                'duration error',
                isNotNull,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blocks submission with a field error when duration is not a '
        'whole/half-day step',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDurationUpdatedEvent('1.3')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.fieldErrors['duration'],
                'duration error',
                isNotNull,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      for (final step in ['0.5', '1', '1.5', '2', '2.5', '10'])
        blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
          'accepts a valid half-day step duration of $step with no field '
          'error',
          build: () => bloc,
          act: (bloc) => bloc.add(EquipmentDurationUpdatedEvent(step)),
          expect: () => [
            isA<EquipmentCostFormEditing>().having(
              (s) => s.data.fieldErrors['duration'],
              'duration error',
              isNull,
            ),
          ],
        );
    });

    group('EquipmentDeliveryFeeUpdatedEvent — bound/NaN checks', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'accepts a delivery fee of exactly 0 as a valid confirmed-free '
        'value with no field error',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDeliveryFeeUpdatedEvent('0')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.deliveryFee, 'deliveryFee', 0)
              .having(
                (s) => s.data.fieldErrors['deliveryFee'],
                'deliveryFee error',
                isNull,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'rejects a negative delivery fee with a field error',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDeliveryFeeUpdatedEvent('-5')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.deliveryFee, 'deliveryFee', -5)
              .having(
                (s) => s.data.fieldErrors['deliveryFee'],
                'deliveryFee error',
                isNotNull,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      for (final bad in ['NaN', 'Infinity', '-Infinity', '1e400'])
        blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
          'rejects a delivery fee of "$bad" with a field error instead of '
          'silently corrupting the total',
          build: () => bloc,
          act: (bloc) => bloc.add(EquipmentDeliveryFeeUpdatedEvent(bad)),
          expect: () => [
            isA<EquipmentCostFormEditing>()
                .having(
                  (s) => s.data.fieldErrors['deliveryFee'],
                  'deliveryFee error',
                  isNotNull,
                )
                .having((s) => s.data.isValid, 'isValid', false),
          ],
        );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'rejects a delivery fee above the maximum with a field error',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const EquipmentDeliveryFeeUpdatedEvent('1000000')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.fieldErrors['deliveryFee'],
                'deliveryFee error',
                isNotNull,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'accepts a delivery fee within bounds with no field error',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDeliveryFeeUpdatedEvent('50')),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.fieldErrors['deliveryFee'],
            'deliveryFee error',
            isNull,
          ),
        ],
      );
    });

    group('EquipmentDeliveryFeeConfirmedEvent', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'does not confirm an out-of-range delivery fee',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentDeliveryFeeUpdatedEvent('-5'))
          ..add(const EquipmentDeliveryFeeConfirmedEvent()),
        skip: 1,
        expect: () => <EquipmentCostFormState>[],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'does not confirm a NaN delivery fee',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentDeliveryFeeUpdatedEvent('NaN'))
          ..add(const EquipmentDeliveryFeeConfirmedEvent()),
        skip: 1,
        expect: () => <EquipmentCostFormState>[],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'confirms a valid delivery fee',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentDeliveryFeeUpdatedEvent('20'))
          ..add(const EquipmentDeliveryFeeConfirmedEvent()),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.deliveryFeeStatus,
            'deliveryFeeStatus',
            DeliveryFeeStatus.confirmed,
          ),
        ],
      );
    });

    group('EquipmentCostSubmittedEvent', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Editing with field errors and does not submit when invalid',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
        ),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.isValid,
            'isValid',
            false,
          ),
        ],
        verify: (_) {
          expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), isEmpty);
        },
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Submitting then Success when the repository call succeeds',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(const EquipmentDurationUpdatedEvent('5'))
            ..add(const EquipmentRateUpdatedEvent('100'))
            ..add(
              const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
            );
        },
        skip: 3,
        expect: () => [
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormSuccess>()
              .having(
                (s) => s.createdItem.itemName,
                'itemName',
                testEquipmentType,
              )
              .having(
                (s) => s.createdItem.estimateId,
                'estimateId',
                testEstimateId,
              )
              .having(
                (s) => (s.createdItem as EquipmentCostItem).dailyRate?.amount,
                'dailyRate',
                100,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Submitting then Failure when the repository call fails',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType =
              SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(const EquipmentDurationUpdatedEvent('5'))
            ..add(const EquipmentRateUpdatedEvent('100'))
            ..add(
              const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
            );
        },
        skip: 3,
        expect: () => [
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.connectionError,
            ),
          ),
        ],
      );
    });

    group('EquipmentOutsizedFeeAcceptedEvent', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'is a no-op when not currently in OutsizedFeeConfirm',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const EquipmentOutsizedFeeAcceptedEvent(estimateId: testEstimateId),
        ),
        expect: () => <EquipmentCostFormState>[],
      );
    });
  });
}
