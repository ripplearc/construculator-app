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
        'is not valid when the item type is only spaces',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged('   '))
            ..add(const EquipmentDurationUpdatedEvent('5'))
            ..add(const EquipmentRateUpdatedEvent('100'));
        },
        skip: 2,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.isItemTypeValid, 'isItemTypeValid', false)
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

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

    group('EquipmentSavedRateRecalledEvent', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'fills dailyRate and marks it ownRateConfirmed for a recalled day '
        'rate, leaving deliveryFee untouched (still unpriced)',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const EquipmentSavedRateRecalledEvent(
            method: EquipmentPricingMethod.day,
            rate: 145,
          ),
        ),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.method,
                'method',
                EquipmentPricingMethod.day,
              )
              .having((s) => s.data.dailyRate, 'dailyRate', 145)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateConfirmed,
              )
              .having((s) => s.data.deliveryFee, 'deliveryFee', isNull),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'marks the line as recalled from recents only when the event says so',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const EquipmentSavedRateRecalledEvent(
            method: EquipmentPricingMethod.job,
            rate: 400,
            fromRecents: true,
          ),
        ),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.recalledFromRecents,
            'recalledFromRecents',
            true,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'a pick from the look-up (fromRecents false) never marks the line as '
        'recalled from recents',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const EquipmentSavedRateRecalledEvent(
            method: EquipmentPricingMethod.job,
            rate: 400,
          ),
        ),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.recalledFromRecents,
            'recalledFromRecents',
            false,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'typing over a line recalled from recents downgrades the rate status '
        'but keeps the recalled-from-recents flag',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            const EquipmentSavedRateRecalledEvent(
              method: EquipmentPricingMethod.job,
              rate: 400,
              fromRecents: true,
            ),
          )
          ..add(const EquipmentRateUpdatedEvent('450')),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateUnconfirmed,
              )
              .having(
                (s) => s.data.recalledFromRecents,
                'recalledFromRecents',
                true,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'keeps the equipment name that was already typed, because picking a '
        'price never renames the line',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged('mini excavator 1.5t'))
            ..add(
              const EquipmentSavedRateRecalledEvent(
                method: EquipmentPricingMethod.day,
                rate: 145,
              ),
            );
        },
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<EquipmentCostFormEditing>());
          expect(
            (state as EquipmentCostFormEditing).data.equipmentType,
            'mini excavator 1.5t',
          );
        },
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'sending the same method again after a recall keeps the confirmed '
        'status',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            const EquipmentSavedRateRecalledEvent(
              method: EquipmentPricingMethod.day,
              rate: 145,
            ),
          )
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.day)),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.rateStatus,
            'rateStatus',
            RateStatus.ownRateConfirmed,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'a recall for the other method switches to it and keeps the status of '
        'the method it left',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentRateUpdatedEvent('100'))
          ..add(
            const EquipmentSavedRateRecalledEvent(
              method: EquipmentPricingMethod.job,
              rate: 400,
            ),
          ),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.method,
                'method',
                EquipmentPricingMethod.job,
              )
              .having((s) => s.data.jobAmount, 'jobAmount', 400)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateConfirmed,
              )
              .having(
                (s) => s.data.otherMethodRateStatus,
                'otherMethodRateStatus',
                RateStatus.ownRateUnconfirmed,
              )
              .having((s) => s.data.dailyRate, 'dailyRate', 100),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'Add stays disabled for a recalled day rate until Duration is typed',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const EquipmentSavedRateRecalledEvent(
            method: EquipmentPricingMethod.day,
            rate: 145,
          ),
        ),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.isValid,
            'isValid',
            false,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'fills jobAmount and marks it ownRateConfirmed for a recalled job '
        'price, with Add already active on arrival (a confirmation, not a '
        'form — Job pricing needs no duration)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
          ..add(
            const EquipmentSavedRateRecalledEvent(
              method: EquipmentPricingMethod.job,
              rate: 400,
            ),
          ),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.jobAmount, 'jobAmount', 400)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateConfirmed,
              )
              .having((s) => s.data.isValid, 'isValid', true),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'a recalled job amount stays editable: typing over it downgrades '
        'rateStatus back to ownRateUnconfirmed, the same as any other typed '
        'value',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            const EquipmentSavedRateRecalledEvent(
              method: EquipmentPricingMethod.job,
              rate: 400,
            ),
          )
          ..add(const EquipmentRateUpdatedEvent('450')),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.jobAmount, 'jobAmount', 450)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateUnconfirmed,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        // Sub-flow D correctness: a Job quote is a separate catalog entry
        // from a Day rate, never derived from it. Switching away from a
        // recalled (ownRateConfirmed) day rate must leave jobAmount
        // untouched — never a computed "duration x dailyRate" value — and
        // must not silently carry the day rate's ownRateConfirmed status
        // over to the job field it was never actually saved under.
        'switching from a recalled day rate to Job never derives jobAmount '
        'from it, and starts the job field at missing, not confirmed',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentDurationUpdatedEvent('4'))
          ..add(
            const EquipmentSavedRateRecalledEvent(
              method: EquipmentPricingMethod.day,
              rate: 145,
            ),
          )
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job)),
        skip: 2,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.jobAmount, 'jobAmount', isNull)
              .having((s) => s.data.dailyRate, 'dailyRate', 145)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.missing,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'switching back to Day after recalling a day rate restores the value '
        'and its confirmed status',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(
            const EquipmentSavedRateRecalledEvent(
              method: EquipmentPricingMethod.day,
              rate: 145,
            ),
          )
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job))
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.day)),
        skip: 2,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.dailyRate, 'dailyRate', 145)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateConfirmed,
              ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'switching back restores a typed Day rate as unconfirmed and keeps '
        'the Job amount typed in between',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentRateUpdatedEvent('100'))
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job))
          ..add(const EquipmentRateUpdatedEvent('300'))
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.day)),
        skip: 3,
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.dailyRate, 'dailyRate', 100)
              .having((s) => s.data.jobAmount, 'jobAmount', 300)
              .having(
                (s) => s.data.rateStatus,
                'rateStatus',
                RateStatus.ownRateUnconfirmed,
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

    group('EquipmentRateUpdatedEvent — bound/NaN checks', () {
      for (final bad in ['0', '0.009', '1000000', 'NaN', 'Infinity']) {
        blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
          'rejects a daily rate of "$bad" with rateOutOfRange',
          build: () => bloc,
          act: (bloc) => bloc.add(EquipmentRateUpdatedEvent(bad)),
          expect: () => [
            isA<EquipmentCostFormEditing>()
                .having(
                  (s) => s.data.fieldErrors[EquipmentFormField.dailyRate],
                  'dailyRate error',
                  EquipmentFieldError.rateOutOfRange,
                )
                .having((s) => s.data.isValid, 'isValid', false),
          ],
        );
      }

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'accepts a daily rate within bounds with no field error',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentRateUpdatedEvent('100')),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.fieldErrors[EquipmentFormField.dailyRate],
            'dailyRate error',
            isNull,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'rejects an out-of-range job amount under the jobAmount key',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job))
          ..add(const EquipmentRateUpdatedEvent('0')),
        skip: 1,
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.fieldErrors[EquipmentFormField.jobAmount],
            'jobAmount error',
            EquipmentFieldError.rateOutOfRange,
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
                (s) => s.data.fieldErrors[EquipmentFormField.duration],
                'duration error',
                isNull,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blocks submission with durationNotPositive when duration is zero '
        '(entered but invalid, unlike a blank field)',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDurationUpdatedEvent('0')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.fieldErrors[EquipmentFormField.duration],
                'duration error',
                EquipmentFieldError.durationNotPositive,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blocks submission with durationNotPositive when duration is '
        'negative',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDurationUpdatedEvent('-1')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.fieldErrors[EquipmentFormField.duration],
                'duration error',
                EquipmentFieldError.durationNotPositive,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blocks submission with durationNotHalfDay when duration is '
        'positive but not a whole/half-day step',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDurationUpdatedEvent('1.3')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.fieldErrors[EquipmentFormField.duration],
                'duration error',
                EquipmentFieldError.durationNotHalfDay,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      for (final step in ['0.5', '1', '1.5', '2', '2.5', '10']) {
        blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
          'accepts a valid half-day step duration of $step with no field '
          'error',
          build: () => bloc,
          act: (bloc) => bloc.add(EquipmentDurationUpdatedEvent(step)),
          expect: () => [
            isA<EquipmentCostFormEditing>().having(
              (s) => s.data.fieldErrors[EquipmentFormField.duration],
              'duration error',
              isNull,
            ),
          ],
        );
      }

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blocks submission with durationTooLarge when duration would '
        'overflow the database column (cost_items.duration is numeric(10,2))',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const EquipmentDurationUpdatedEvent('100000000')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having(
                (s) => s.data.fieldErrors[EquipmentFormField.duration],
                'duration error',
                EquipmentFieldError.durationTooLarge,
              )
              .having((s) => s.data.isValid, 'isValid', false),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'accepts a duration right at the database column limit',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const EquipmentDurationUpdatedEvent('99999999.5')),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.fieldErrors[EquipmentFormField.duration],
            'duration error',
            isNull,
          ),
        ],
      );
    });

    group('EquipmentDeliveryFeeUpdatedEvent — unusable values', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'accepts a delivery fee of exactly 0',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDeliveryFeeUpdatedEvent('0')),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.deliveryFee,
            'deliveryFee',
            0,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'accepts a delivery fee within bounds',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDeliveryFeeUpdatedEvent('50')),
        expect: () => [
          isA<EquipmentCostFormEditing>()
              .having((s) => s.data.deliveryFee, 'deliveryFee', 50)
              .having(
                (s) => s.data.fieldErrors[EquipmentFormField.deliveryFee],
                'deliveryFee error',
                isNull,
              ),
        ],
      );

      for (final bad in [
        '-5',
        'NaN',
        'Infinity',
        '-Infinity',
        '1e400',
        '1000000',
      ]) {
        blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
          'ignores a delivery fee of "$bad" and keeps the previous fee with '
          'no error',
          build: () => bloc,
          act: (bloc) {
            bloc
              ..add(const EquipmentDeliveryFeeUpdatedEvent('25'))
              ..add(EquipmentDeliveryFeeUpdatedEvent(bad));
          },
          expect: () => [
            isA<EquipmentCostFormEditing>().having(
              (s) => s.data.deliveryFee,
              'deliveryFee',
              25,
            ),
          ],
          verify: (bloc) {
            expect(bloc.state, isA<EquipmentCostFormEditing>());
            final data = (bloc.state as EquipmentCostFormEditing).data;
            expect(data.deliveryFee, 25);
            expect(data.fieldErrors[EquipmentFormField.deliveryFee], isNull);
          },
        );
      }

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'clears the delivery fee when the text is emptied',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentDeliveryFeeUpdatedEvent('25'))
            ..add(const EquipmentDeliveryFeeUpdatedEvent(''));
        },
        verify: (bloc) {
          final data = (bloc.state as EquipmentCostFormEditing).data;
          expect(data.deliveryFee, isNull);
        },
      );
    });

    group('EquipmentDescriptionUpdatedEvent', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'stores typed note text in description',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const EquipmentDescriptionUpdatedEvent('Leave at gate')),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.description,
            'description',
            'Leave at gate',
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'blank note text gives a null description',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentDescriptionUpdatedEvent('   ')),
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.description,
            'description',
            isNull,
          ),
        ],
      );
    });

    group('EquipmentCostSubmittedEvent', () {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'sends the typed delivery fee as final (no status) in the insert '
        'payload',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(const EquipmentDurationUpdatedEvent('5'))
            ..add(const EquipmentRateUpdatedEvent('100'))
            ..add(const EquipmentDeliveryFeeUpdatedEvent('20'))
            ..add(
              const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
            );
        },
        skip: 4,
        expect: () => [
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormSuccess>(),
        ],
        verify: (_) {
          final call = fakeSupabaseWrapper.getMethodCallsFor('insert').single;
          final data = call['data'] as Map;
          expect(data['delivery_fee'], 20.0);
          expect(data['item_total_cost'], 520.0);
          expect(data.containsKey('delivery_fee_status'), isFalse);
        },
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'adds the typed delivery fee to the total of a Job line',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(
              const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job),
            )
            ..add(const EquipmentRateUpdatedEvent('400'))
            ..add(const EquipmentDeliveryFeeUpdatedEvent('20'))
            ..add(
              const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
            );
        },
        skip: 4,
        expect: () => [
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormSuccess>(),
        ],
        verify: (_) {
          final data =
              fakeSupabaseWrapper.getMethodCallsFor('insert').single['data']
                  as Map;
          expect(data['delivery_fee'], 20.0);
          expect(data['item_total_cost'], 420.0);
        },
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'a second Submitted after Success does not insert twice',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(const EquipmentDurationUpdatedEvent('5'))
            ..add(const EquipmentRateUpdatedEvent('100'))
            ..add(const EquipmentCostSubmittedEvent(estimateId: testEstimateId))
            ..add(
              const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
            );
        },
        verify: (_) {
          expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), hasLength(1));
        },
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'ignores Submitted while a submit is already in flight',
        build: () => bloc,
        seed: () => const EquipmentCostFormSubmitting(
          EquipmentCostFormData(
            equipmentType: testEquipmentType,
            duration: 5,
            dailyRate: 100,
            isValid: true,
          ),
        ),
        act: (bloc) => bloc.add(
          const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
        ),
        expect: () => const <EquipmentCostFormState>[],
        verify: (_) {
          expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), isEmpty);
        },
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'sends a null delivery_fee when the delivery fee is left blank',
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
          isA<EquipmentCostFormSuccess>(),
        ],
        verify: (_) {
          final call = fakeSupabaseWrapper.getMethodCallsFor('insert').single;
          final data = call['data'] as Map;
          expect(data['delivery_fee'], isNull);
        },
      );

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
              )
              .having((s) => s.createdItem.itemTotalCost, 'itemTotalCost', 500)
              .having((s) => s.createdItem.calculation, 'calculation', {
                'daily_rate': 100.0,
                'duration': 5.0,
              }),
        ],
        verify: (_) {
          // A not-yet-created item must not send an empty id: cost_items.id
          // is a uuid column, and Postgres rejects '' with error 22P02. The
          // database default should generate the id instead (B1).
          final call = fakeSupabaseWrapper.getMethodCallsFor('insert').single;
          final data = call['data'] as Map;
          expect(data.containsKey('id'), isFalse);
          // rate_status_enum in construculator-backend #58 only accepts
          // these four values; any other string fails the real insert with
          // error 22P02 even though FakeSupabaseWrapper accepts any text (B5).
          expect(data['rate_status'], 'own_rate_unconfirmed');
          expect(
            data['rate_status'],
            isIn(const [
              'sample_rate_unverified',
              'own_rate_unconfirmed',
              'own_rate_confirmed',
              'missing',
            ]),
          );
        },
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'emits Submitting then Success for a Job submit, with duration and '
        'dailyRate left null on the created item',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(
              const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job),
            )
            ..add(const EquipmentRateUpdatedEvent('3000'))
            ..add(
              const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
            );
        },
        skip: 3,
        expect: () => [
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormSuccess>()
              .having(
                (s) => (s.createdItem as EquipmentCostItem).jobAmount?.amount,
                'jobAmount',
                3000,
              )
              .having(
                (s) => (s.createdItem as EquipmentCostItem).duration,
                'duration',
                isNull,
              )
              .having(
                (s) => (s.createdItem as EquipmentCostItem).dailyRate,
                'dailyRate',
                isNull,
              )
              .having((s) => s.createdItem.itemTotalCost, 'itemTotalCost', 3000)
              .having((s) => s.createdItem.calculation, 'calculation', {
                'job_amount': 3000.0,
              }),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'switching Day to Job then submitting drops the day-pricing fields '
        'instead of sending both',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(const EquipmentDurationUpdatedEvent('5'))
            ..add(const EquipmentRateUpdatedEvent('100'))
            ..add(
              const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job),
            )
            ..add(const EquipmentRateUpdatedEvent('3000'))
            ..add(
              const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
            );
        },
        skip: 5,
        expect: () => [
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormSuccess>()
              .having(
                (s) => (s.createdItem as EquipmentCostItem).duration,
                'duration',
                isNull,
              )
              .having(
                (s) => (s.createdItem as EquipmentCostItem).dailyRate,
                'dailyRate',
                isNull,
              )
              .having(
                (s) => (s.createdItem as EquipmentCostItem).jobAmount?.amount,
                'jobAmount',
                3000,
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

    group('outsized delivery fee', () {
      void fillDay(EquipmentCostFormBloc bloc, {required String fee}) {
        bloc
          ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
          ..add(const EquipmentDurationUpdatedEvent('5'))
          ..add(const EquipmentRateUpdatedEvent('100'))
          ..add(EquipmentDeliveryFeeUpdatedEvent(fee));
      }

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'submitting a Day fee above duration x rate emits OutsizedFeeConfirm '
        'without Submitting',
        build: () => bloc,
        act: (bloc) {
          fillDay(bloc, fee: '501');
          bloc.add(
            const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
          );
        },
        skip: 4,
        expect: () => [isA<EquipmentCostFormOutsizedFeeConfirm>()],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'submitting a Day fee equal to duration x rate goes straight to '
        'Submitting',
        build: () => bloc,
        act: (bloc) {
          fillDay(bloc, fee: '500');
          bloc.add(
            const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
          );
        },
        skip: 4,
        expect: () => [
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormSuccess>(),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'submitting a Job fee above the job amount emits OutsizedFeeConfirm',
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const EquipmentCostItemTypeChanged(testEquipmentType))
            ..add(
              const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job),
            )
            ..add(const EquipmentRateUpdatedEvent('3000'))
            ..add(const EquipmentDeliveryFeeUpdatedEvent('8500'))
            ..add(
              const EquipmentCostSubmittedEvent(estimateId: testEstimateId),
            );
        },
        skip: 4,
        expect: () => [isA<EquipmentCostFormOutsizedFeeConfirm>()],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'Add it submits the fee as typed',
        build: () => bloc,
        act: (bloc) {
          fillDay(bloc, fee: '8500');
          bloc
            ..add(const EquipmentCostSubmittedEvent(estimateId: testEstimateId))
            ..add(
              const EquipmentOutsizedFeeAcceptedEvent(
                estimateId: testEstimateId,
              ),
            );
        },
        skip: 5,
        expect: () => [
          isA<EquipmentCostFormSubmitting>(),
          isA<EquipmentCostFormSuccess>().having(
            (s) => (s.createdItem as EquipmentCostItem).deliveryFee?.amount,
            'deliveryFee',
            8500,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'Go back returns to Editing with the typed fee kept',
        build: () => bloc,
        act: (bloc) {
          fillDay(bloc, fee: '8500');
          bloc
            ..add(const EquipmentCostSubmittedEvent(estimateId: testEstimateId))
            ..add(const EquipmentOutsizedFeeDeclinedEvent());
        },
        skip: 5,
        expect: () => [
          isA<EquipmentCostFormEditing>().having(
            (s) => s.data.deliveryFee,
            'deliveryFee',
            8500,
          ),
        ],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'Add it is a no-op when not currently in OutsizedFeeConfirm',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const EquipmentOutsizedFeeAcceptedEvent(estimateId: testEstimateId),
        ),
        expect: () => <EquipmentCostFormState>[],
      );

      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        'Go back is a no-op when not currently in OutsizedFeeConfirm',
        build: () => bloc,
        act: (bloc) => bloc.add(const EquipmentOutsizedFeeDeclinedEvent()),
        expect: () => <EquipmentCostFormState>[],
      );
    });
  });
}
