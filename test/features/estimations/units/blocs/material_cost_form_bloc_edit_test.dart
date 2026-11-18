import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../helpers/cost_item_test_data_map_factory.dart';

void main() {
  group('MaterialCostFormBloc editing an existing line', () {
    const estimateId = 'estimate-123';
    const itemId = 'item-1';

    late MaterialCostFormBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late CostItemRepository repository;
    late LastUsedUnitRepository lastUsedUnits;
    late FakeStorageService storage;
    late FakeAuthRepository auth;

    Future<MaterialCostItem> storedLine() async {
      final items = await repository.getCostItemsForEstimate(estimateId);
      return items.getRightOrNull()!.single as MaterialCostItem;
    }

    void seedLine() =>
        fakeSupabaseWrapper.addTableData(DatabaseConstants.costItemsTable, [
          CostItemTestDataMapFactory.createMaterialItemData(
            id: itemId,
            estimateId: estimateId,
            itemName: 'Rebar',
            unitPrice: 100.0,
            quantity: 5.0,
            unit: 'pieces',
            itemTotalCost: 500.0,
            rateStatus: 'own_rate_confirmed',
          ),
        ]);

    Future<void> open(MaterialCostFormBloc bloc) async =>
        bloc.add(MaterialCostEditOpened(await storedLine()));

    setUpAll(() {
      final clock = FakeClockImpl();
      storage = FakeStorageService();
      auth = FakeAuthRepository(clock: clock);
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: clock),
          ),
        ),
      );
      Modular.replaceInstance<StorageService>(storage);
      Modular.replaceInstance<AuthRepository>(auth);
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository = Modular.get<CostItemRepository>();
      lastUsedUnits = Modular.get<LastUsedUnitRepository>();
    });

    tearDownAll(Modular.dispose);

    setUp(() {
      fakeSupabaseWrapper.reset();
      storage.reset();
      auth.reset();
      auth.setCurrentCredentials(
        UserCredential(
          id: 'account-1',
          email: 'a@example.com',
          metadata: const {},
          createdAt: DateTime(2026),
        ),
      );
      bloc = Modular.get<MaterialCostFormBloc>();
    });

    tearDown(() => bloc.close());

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'opens with every stored value in the form',
      setUp: seedLine,
      build: () => bloc,
      act: open,
      expect: () => [
        isA<MaterialCostFormEditing>()
            .having((s) => s.data.itemName, 'name', 'Rebar')
            .having((s) => s.data.quantity, 'quantity', 5.0)
            .having((s) => s.data.unit, 'unit', Unit.pieces)
            .having((s) => s.data.rate, 'rate', 100.0)
            .having(
              (s) => s.data.rateStatus,
              'rateStatus',
              RateStatus.ownRateConfirmed,
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

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'reports no change to the estimate total until a field changes',
      setUp: seedLine,
      build: () => bloc,
      act: open,
      verify: (bloc) =>
          expect(bloc.state.data.changeInEstimateTotal, closeTo(0, 0.001)),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'reports the change to the estimate total when the quantity grows',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialQuantityUpdated('7'));
      },
      verify: (bloc) =>
          expect(bloc.state.data.changeInEstimateTotal, closeTo(200, 0.001)),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'reports a negative change when the rate falls',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialRateUpdated('85.50'));
      },
      verify: (bloc) =>
          expect(bloc.state.data.changeInEstimateTotal, closeTo(-72.5, 0.001)),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'a new line has no change to report',
      build: () => bloc,
      act: (bloc) => bloc.add(const MaterialQuantityUpdated('7')),
      verify: (bloc) => expect(bloc.state.data.changeInEstimateTotal, isNull),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'names the stored line while the name field is changed',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialCostItemTypeChanged('Steel bar'));
      },
      verify: (bloc) {
        expect(bloc.state.data.itemName, 'Steel bar');
        expect(bloc.state.data.lineName, 'Rebar');
      },
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'names a new line by the name typed so far',
      build: () => bloc,
      act: (bloc) => bloc.add(const MaterialCostItemTypeChanged('Steel bar')),
      verify: (bloc) => expect(bloc.state.data.lineName, 'Steel bar'),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'marks the form changed after an edit and unchanged after it is undone',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialQuantityUpdated('7'));
        bloc.add(const MaterialQuantityUpdated('5'));
      },
      expect: () => [
        isA<MaterialCostFormEditing>(),
        isA<MaterialCostFormEditing>().having(
          (s) => s.data.hasUnsavedChanges,
          'changed',
          true,
        ),
        isA<MaterialCostFormEditing>().having(
          (s) => s.data.hasUnsavedChanges,
          'changed',
          false,
        ),
      ],
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'typing the stored rate again keeps the stored rate status',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialRateUpdated('100'));
      },
      verify: (bloc) =>
          expect(bloc.state.data.rateStatus, RateStatus.ownRateConfirmed),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'typing a different rate makes the rate status the typed own rate',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialRateUpdated('120'));
      },
      verify: (bloc) =>
          expect(bloc.state.data.rateStatus, RateStatus.ownRateUnconfirmed),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'saving changes the stored line instead of adding another',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialQuantityUpdated('7'));
        bloc.add(const MaterialCostFormSubmitted(estimateId: estimateId));
      },
      skip: 2,
      expect: () => [
        isA<MaterialCostFormSubmitting>(),
        isA<MaterialCostFormSuccess>().having(
          (s) => s.savedItem.id,
          'id',
          itemId,
        ),
      ],
      verify: (_) async {
        final line = await storedLine();
        expect(line.id, itemId);
        expect(line.quantity.value, 7.0);
        expect(line.itemTotalCost, 700.0);
        expect(line.createdAt, DateTime.utc(2024));
        expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), isEmpty);
      },
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'saving an edit leaves the remembered unit alone',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialUnitSelected(Unit.bags));
        bloc.add(const MaterialCostFormSubmitted(estimateId: estimateId));
      },
      verify: (_) async => expect(
        await lastUsedUnits.getLastUnit(CostItemType.material),
        isNull,
      ),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'a failed save keeps the stored line as it was and reports the failure',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialQuantityUpdated('7'));
        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        bloc.add(const MaterialCostFormSubmitted(estimateId: estimateId));
      },
      skip: 2,
      expect: () => [
        isA<MaterialCostFormSubmitting>(),
        isA<MaterialCostFormFailure>()
            .having((s) => s.whileDeleting, 'whileDeleting', false)
            .having(
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
        expect((await storedLine()).quantity.value, 5.0);
      },
    );

    void seedRichLine() =>
        fakeSupabaseWrapper.addTableData(DatabaseConstants.costItemsTable, [
          CostItemTestDataMapFactory.createMaterialItemData(
            id: itemId,
            estimateId: estimateId,
            itemName: 'Rebar',
            description: 'Back wall only',
            productLink: 'https://example.test/rebar',
            wastePercent: 10.0,
            unitPrice: 100.0,
            quantity: 5.0,
            unit: 'pieces',
            itemTotalCost: 500.0,
            rateStatus: 'own_rate_confirmed',
            quantityProvenance: 'from_calculator',
            calculatorFormula: '47.24in x 94.49in',
          ),
        ]);

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'puts back the stored rate status when the stored rate is typed again',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc
          ..add(const MaterialRateUpdated('10'))
          ..add(const MaterialRateUpdated('100'));
      },
      verify: (bloc) {
        expect(bloc.state.data.rate, 100.0);
        expect(bloc.state.data.rateStatus, RateStatus.ownRateConfirmed);
        expect(bloc.state.data.hasUnsavedChanges, isFalse);
      },
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'marks the rate as the own rate while a different rate is typed',
      setUp: seedLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc.add(const MaterialRateUpdated('10'));
      },
      verify: (bloc) =>
          expect(bloc.state.data.rateStatus, RateStatus.ownRateUnconfirmed),
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'saving only a new name keeps the note, link, waste, formula and '
      'quantity source',
      setUp: seedRichLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc
          ..add(const MaterialCostItemTypeChanged('Steel bar'))
          ..add(const MaterialCostFormSubmitted(estimateId: estimateId));
      },
      verify: (_) async {
        final line = await storedLine();
        expect(line.itemName, 'Steel bar');
        expect(line.description, 'Back wall only');
        expect(line.productLink, 'https://example.test/rebar');
        expect(line.wastePercent, 10.0);
        expect(line.quantityProvenance, QuantityProvenance.fromCalculator);
        expect(line.calculatorFormula, '47.24in x 94.49in');
        expect(line.quantity.value, 5.0);
      },
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'saving a new quantity makes the quantity manual and drops the formula',
      setUp: seedRichLine,
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc
          ..add(const MaterialQuantityUpdated('7'))
          ..add(const MaterialCostFormSubmitted(estimateId: estimateId));
      },
      verify: (_) async {
        final line = await storedLine();
        expect(line.quantity.value, 7.0);
        expect(line.quantityProvenance, QuantityProvenance.manual);
        expect(line.calculatorFormula, isNull);
        expect(line.description, 'Back wall only');
        expect(line.wastePercent, 10.0);
      },
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'a remembered unit that arrives late does not replace the stored unit',
      setUp: () {
        seedLine();
        return lastUsedUnits.saveLastUnit(CostItemType.material, Unit.meters);
      },
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc
          ..add(const MaterialCostFormStarted())
          ..add(const MaterialQuantityUpdated('5'));
      },
      verify: (bloc) {
        expect(bloc.state.data.unit, Unit.pieces);
        expect(bloc.state.data.hasUnsavedChanges, isFalse);
      },
    );

    blocTest<MaterialCostFormBloc, MaterialCostFormState>(
      'saving a change to a line does not change the remembered unit',
      setUp: () {
        seedLine();
        return lastUsedUnits.saveLastUnit(CostItemType.material, Unit.meters);
      },
      build: () => bloc,
      act: (bloc) async {
        await open(bloc);
        bloc
          ..add(const MaterialQuantityUpdated('7'))
          ..add(const MaterialCostFormSubmitted(estimateId: estimateId));
      },
      verify: (_) async => expect(
        await lastUsedUnits.getLastUnit(CostItemType.material),
        Unit.meters,
      ),
    );

    group('deleting the line', () {
      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'removes the stored line and ends in Deleted',
        setUp: seedLine,
        build: () => bloc,
        act: (bloc) async {
          await open(bloc);
          bloc.add(const MaterialCostDeleteRequested());
        },
        skip: 1,
        expect: () => [
          isA<MaterialCostFormSubmitting>(),
          isA<MaterialCostFormDeleted>(),
        ],
        verify: (_) async {
          final items = await repository.getCostItemsForEstimate(estimateId);
          expect(items.getRightOrNull(), isEmpty);
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'a second Delete after the line is deleted does nothing',
        setUp: seedLine,
        build: () => bloc,
        act: (bloc) async {
          await open(bloc);
          bloc.add(const MaterialCostDeleteRequested());
          await bloc.stream.firstWhere((s) => s is MaterialCostFormDeleted);
          bloc.add(const MaterialCostDeleteRequested());
        },
        skip: 1,
        expect: () => [
          isA<MaterialCostFormSubmitting>(),
          isA<MaterialCostFormDeleted>(),
        ],
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'keeps the line and reports a delete failure when the delete fails',
        setUp: seedLine,
        build: () => bloc,
        act: (bloc) async {
          await open(bloc);
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          bloc.add(const MaterialCostDeleteRequested());
        },
        skip: 2,
        expect: () => [
          isA<MaterialCostFormFailure>().having(
            (s) => s.whileDeleting,
            'whileDeleting',
            true,
          ),
        ],
        verify: (_) async {
          fakeSupabaseWrapper.shouldThrowOnDelete = false;
          expect(await storedLine(), isA<MaterialCostItem>());
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'drops the delete failure once a field is changed',
        setUp: seedLine,
        build: () => bloc,
        act: (bloc) async {
          await open(bloc);
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          bloc.add(const MaterialCostDeleteRequested());
          await bloc.stream.firstWhere((s) => s is MaterialCostFormFailure);
          bloc.add(const MaterialQuantityUpdated('7'));
        },
        verify: (bloc) => expect(bloc.state, isA<MaterialCostFormEditing>()),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'ignores a save once the line is deleted',
        setUp: seedLine,
        build: () => bloc,
        act: (bloc) async {
          await open(bloc);
          bloc.add(const MaterialCostDeleteRequested());
          await bloc.stream.firstWhere((s) => s is MaterialCostFormDeleted);
          bloc.add(const MaterialCostFormSubmitted(estimateId: estimateId));
        },
        verify: (bloc) {
          expect(bloc.state, isA<MaterialCostFormDeleted>());
          expect(fakeSupabaseWrapper.getMethodCallsFor('update'), isEmpty);
        },
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'a failed save is not reported as a delete failure',
        setUp: seedLine,
        build: () => bloc,
        act: (bloc) async {
          await open(bloc);
          bloc.add(const MaterialQuantityUpdated('7'));
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          bloc.add(const MaterialCostFormSubmitted(estimateId: estimateId));
        },
        verify: (bloc) => expect(
          (bloc.state as MaterialCostFormFailure).whileDeleting,
          false,
        ),
      );

      blocTest<MaterialCostFormBloc, MaterialCostFormState>(
        'a new line cannot be deleted',
        build: () => bloc,
        act: (bloc) => bloc.add(const MaterialCostDeleteRequested()),
        expect: () => <MaterialCostFormState>[],
        verify: (_) =>
            expect(fakeSupabaseWrapper.getMethodCallsFor('delete'), isEmpty),
      );
    });
  });
}
