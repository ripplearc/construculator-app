import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('EquipmentCostFormData live total and submit blocker', () {
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

    const name = EquipmentCostItemTypeChanged('Scissor lift');
    const job = EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job);

    final cases =
        <
          String,
          ({
            List<EquipmentCostFormEvent> events,
            EquipmentSubmitBlocker? blocker,
            double total,
          })
        >{
          'a new form needs a name': (
            events: [const EquipmentCostItemTypeChanged('')],
            blocker: EquipmentSubmitBlocker.missingName,
            total: 0,
          ),
          'a blank name still needs a name': (
            events: [
              const EquipmentCostItemTypeChanged('   '),
              const EquipmentDurationUpdatedEvent('4'),
              const EquipmentRateUpdatedEvent('145'),
            ],
            blocker: EquipmentSubmitBlocker.missingName,
            total: 580,
          ),
          'a Day line with a name needs a duration': (
            events: [name],
            blocker: EquipmentSubmitBlocker.missingDuration,
            total: 0,
          ),
          'a zero duration must be fixed': (
            events: [name, const EquipmentDurationUpdatedEvent('0')],
            blocker: EquipmentSubmitBlocker.durationNotAboveZero,
            total: 0,
          ),
          'a negative duration must be fixed': (
            events: [name, const EquipmentDurationUpdatedEvent('-1')],
            blocker: EquipmentSubmitBlocker.durationNotAboveZero,
            total: 0,
          ),
          'a duration that is not a half day must be fixed': (
            events: [name, const EquipmentDurationUpdatedEvent('1.3')],
            blocker: EquipmentSubmitBlocker.invalidDuration,
            total: 0,
          ),
          'a duration above the column limit must be fixed': (
            events: [name, const EquipmentDurationUpdatedEvent('999999999')],
            blocker: EquipmentSubmitBlocker.invalidDuration,
            total: 0,
          ),
          'a Day line with a duration needs a rate': (
            events: [name, const EquipmentDurationUpdatedEvent('4')],
            blocker: EquipmentSubmitBlocker.missingRate,
            total: 0,
          ),
          'a rate out of range must be fixed': (
            events: [
              name,
              const EquipmentDurationUpdatedEvent('4'),
              const EquipmentRateUpdatedEvent('0'),
            ],
            blocker: EquipmentSubmitBlocker.invalidRate,
            total: 0,
          ),
          'a missing duration is reported before a missing rate': (
            events: [name, const EquipmentRateUpdatedEvent('145')],
            blocker: EquipmentSubmitBlocker.missingDuration,
            total: 0,
          ),
          'a valid Day line totals duration times rate': (
            events: [
              name,
              const EquipmentDurationUpdatedEvent('4'),
              const EquipmentRateUpdatedEvent('145'),
            ],
            blocker: null,
            total: 580,
          ),
          'a line is rounded to the cent, half a cent rounding up': (
            events: [
              name,
              const EquipmentDurationUpdatedEvent('0.5'),
              const EquipmentRateUpdatedEvent('0.01'),
            ],
            blocker: null,
            total: 0.01,
          ),
          'a half day counts': (
            events: [
              name,
              const EquipmentDurationUpdatedEvent('1.5'),
              const EquipmentRateUpdatedEvent('145'),
            ],
            blocker: null,
            total: 217.5,
          ),
          'delivery is added after the Day rate math': (
            events: [
              name,
              const EquipmentDurationUpdatedEvent('4'),
              const EquipmentRateUpdatedEvent('145'),
              const EquipmentDeliveryFeeUpdatedEvent('85'),
            ],
            blocker: null,
            total: 665,
          ),
          'a free delivery fee leaves the total alone': (
            events: [
              name,
              const EquipmentDurationUpdatedEvent('4'),
              const EquipmentRateUpdatedEvent('145'),
              const EquipmentDeliveryFeeUpdatedEvent('0'),
            ],
            blocker: null,
            total: 580,
          ),
          'a delivery fee out of range is ignored': (
            events: [
              name,
              const EquipmentDurationUpdatedEvent('4'),
              const EquipmentRateUpdatedEvent('145'),
              const EquipmentDeliveryFeeUpdatedEvent('9999999'),
            ],
            blocker: null,
            total: 580,
          ),
          'a Job line needs an amount': (
            events: [name, job],
            blocker: EquipmentSubmitBlocker.missingAmount,
            total: 0,
          ),
          'a Job amount out of range must be fixed': (
            events: [name, job, const EquipmentRateUpdatedEvent('0')],
            blocker: EquipmentSubmitBlocker.invalidAmount,
            total: 0,
          ),
          'a Job line ignores a typed duration and rate': (
            events: [
              name,
              const EquipmentDurationUpdatedEvent('4'),
              const EquipmentRateUpdatedEvent('145'),
              job,
            ],
            blocker: EquipmentSubmitBlocker.missingAmount,
            total: 0,
          ),
          'a valid Job line totals the amount': (
            events: [name, job, const EquipmentRateUpdatedEvent('520')],
            blocker: null,
            total: 520,
          ),
          'delivery is added after the Job amount': (
            events: [
              name,
              job,
              const EquipmentRateUpdatedEvent('520'),
              const EquipmentDeliveryFeeUpdatedEvent('85'),
            ],
            blocker: null,
            total: 605,
          ),
        };

    for (final entry in cases.entries) {
      blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
        entry.key,
        build: () => Modular.get<EquipmentCostFormBloc>(),
        act: (bloc) => entry.value.events.forEach(bloc.add),
        verify: (bloc) {
          expect(bloc.state.formData.submitBlocker, entry.value.blocker);
          expect(bloc.state.formData.lineTotal, entry.value.total);
        },
      );
    }
  });
}
