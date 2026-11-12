import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../helpers/cost_item_test_data_map_factory.dart';

void main() {
  group('EquipmentCostFormBloc editing an existing line', () {
    const estimateId = 'estimate-123';
    const itemId = 'item-1';

    late EquipmentCostFormBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late CostItemRepository repository;

    Future<EquipmentCostItem> storedLine() async {
      final items = await repository.getCostItemsForEstimate(estimateId);
      return items.getRightOrNull()!.single as EquipmentCostItem;
    }

    void seedLine({
      String pricingMethod = 'day',
      double? deliveryFee = 85.0,
      double itemTotalCost = 685.0,
    }) => fakeSupabaseWrapper.addTableData(DatabaseConstants.costItemsTable, [
      CostItemTestDataMapFactory.createEquipmentItemData(
        id: itemId,
        estimateId: estimateId,
        itemName: 'Scissor lift',
        pricingMethod: pricingMethod,
        duration: 3.0,
        dailyRate: 200.0,
        jobAmount: 600.0,
        deliveryFee: deliveryFee,
        itemTotalCost: itemTotalCost,
      ),
    ]);

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
      repository = Modular.get<CostItemRepository>();
    });

    tearDownAll(Modular.dispose);

    setUp(() {
      fakeSupabaseWrapper.reset();
      bloc = Modular.get<EquipmentCostFormBloc>();
    });

    tearDown(() => bloc.close());

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'opens a day line with every stored value in the form',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async =>
          bloc.add(EquipmentCostEditOpened(await storedLine())),
      expect: () => [
        isA<EquipmentCostFormEditing>()
            .having((s) => s.data.method, 'method', EquipmentPricingMethod.day)
            .having((s) => s.data.equipmentType, 'name', 'Scissor lift')
            .having((s) => s.data.duration, 'duration', 3.0)
            .having((s) => s.data.dailyRate, 'dailyRate', 200.0)
            .having((s) => s.data.deliveryFee, 'deliveryFee', 85.0)
            .having(
              (s) => s.data.rateStatus,
              'rateStatus',
              RateStatus.sampleRateUnverified,
            )
            .having(
              (s) => s.data.description,
              'description',
              'Test description',
            )
            .having((s) => s.data.isEditingExistingLine, 'isEditing', true)
            .having((s) => s.data.isValid, 'isValid', true)
            .having(
              (s) => s.data.hasUnsavedChanges,
              'hasUnsavedChanges',
              false,
            ),
      ],
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'opens a job line with its amount and no duration',
      setUp: () => seedLine(
        pricingMethod: 'job',
        deliveryFee: null,
        itemTotalCost: 600.0,
      ),
      build: () => bloc,
      act: (bloc) async =>
          bloc.add(EquipmentCostEditOpened(await storedLine())),
      expect: () => [
        isA<EquipmentCostFormEditing>()
            .having((s) => s.data.method, 'method', EquipmentPricingMethod.job)
            .having((s) => s.data.jobAmount, 'jobAmount', 600.0)
            .having((s) => s.data.duration, 'duration', isNull)
            .having((s) => s.data.deliveryFee, 'deliveryFee', isNull),
      ],
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'reports no change to the estimate total until a field changes',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async =>
          bloc.add(EquipmentCostEditOpened(await storedLine())),
      verify: (bloc) => expect(bloc.state.formData.changeInEstimateTotal, 0.0),
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'reports the change to the estimate total when the duration grows',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        bloc.add(EquipmentCostEditOpened(await storedLine()));
        bloc.add(const EquipmentDurationUpdatedEvent('4'));
      },
      verify: (bloc) =>
          expect(bloc.state.formData.changeInEstimateTotal, 200.0),
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'reports a negative change when the delivery fee is removed',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        bloc.add(EquipmentCostEditOpened(await storedLine()));
        bloc.add(const EquipmentDeliveryFeeUpdatedEvent(''));
      },
      verify: (bloc) =>
          expect(bloc.state.formData.changeInEstimateTotal, -85.0),
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'a new line has no change to report',
      build: () => bloc,
      act: (bloc) => bloc.add(const EquipmentDurationUpdatedEvent('4')),
      verify: (bloc) =>
          expect(bloc.state.formData.changeInEstimateTotal, isNull),
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'marks the form changed after an edit and unchanged after it is undone',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        bloc.add(EquipmentCostEditOpened(await storedLine()));
        bloc.add(const EquipmentDurationUpdatedEvent('4'));
        bloc.add(const EquipmentDurationUpdatedEvent('3'));
      },
      expect: () => [
        isA<EquipmentCostFormEditing>(),
        isA<EquipmentCostFormEditing>().having(
          (s) => s.data.hasUnsavedChanges,
          'changed',
          true,
        ),
        isA<EquipmentCostFormEditing>().having(
          (s) => s.data.hasUnsavedChanges,
          'changed',
          false,
        ),
      ],
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'saving changes the stored line instead of adding another',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        bloc.add(EquipmentCostEditOpened(await storedLine()));
        bloc.add(const EquipmentDurationUpdatedEvent('4'));
        bloc.add(const EquipmentCostSubmittedEvent(estimateId: estimateId));
      },
      skip: 2,
      expect: () => [
        isA<EquipmentCostFormSubmitting>(),
        isA<EquipmentCostFormSuccess>().having(
          (s) => s.createdItem.id,
          'id',
          itemId,
        ),
      ],
      verify: (_) async {
        final line = await storedLine();
        expect(line.id, itemId);
        expect(line.duration, 4.0);
        expect(line.itemTotalCost, 885.0);
        expect(line.createdAt, DateTime.utc(2024));
        expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), isEmpty);
      },
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'saving a day line switched to job stores the job amount and drops the days',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        bloc.add(EquipmentCostEditOpened(await storedLine()));
        bloc.add(
          const EquipmentMethodSwitchedEvent(EquipmentPricingMethod.job),
        );
        bloc.add(const EquipmentRateUpdatedEvent('500'));
        bloc.add(const EquipmentCostSubmittedEvent(estimateId: estimateId));
      },
      verify: (_) async {
        final line = await storedLine();
        expect(line.pricingMethod, EquipmentPricingMethod.job);
        expect(line.jobAmount?.amount, 500.0);
        expect(line.duration, isNull);
        expect(line.itemTotalCost, 585.0);
      },
    );

    blocTest<EquipmentCostFormBloc, EquipmentCostFormState>(
      'a failed save keeps the stored line as it was and reports the failure',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        bloc.add(EquipmentCostEditOpened(await storedLine()));
        bloc.add(const EquipmentDurationUpdatedEvent('4'));
        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        bloc.add(const EquipmentCostSubmittedEvent(estimateId: estimateId));
      },
      skip: 2,
      expect: () => [
        isA<EquipmentCostFormSubmitting>(),
        isA<EquipmentCostFormFailure>().having(
          (s) => s.failure,
          'failure',
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.unexpectedError,
          ),
        ),
      ],
      verify: (_) async {
        fakeSupabaseWrapper.shouldThrowOnUpdate = false;
        expect((await storedLine()).duration, 3.0);
      },
    );
  });
}
