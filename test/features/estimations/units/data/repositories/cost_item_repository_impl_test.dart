import 'package:construculator/features/estimation/data/repositories/cost_item_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

void main() {

  group('CostItemRepositoryImpl', () {
    late CostItemRepositoryImpl repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    final testItem = MaterialCostItem(
      id: 'item-1',
      estimateId: 'estimate-1',
      itemName: 'Cement',
      calculation: {},
      itemTotalCost: 100.0,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      currency: 'USD',
      unitPrice: const Money(amount: 10.0),
      quantity: const Quantity(value: 10.0, unit: Unit.bags),
    );

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
      repository =
          Modular.get<CostItemRepository>() as CostItemRepositoryImpl;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    group('createCostItem', () {
      test('returns Right with created entity on success', () async {
        final result = await repository.createCostItem(testItem);

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isA<MaterialCostItem>());
      });

      test(
        'maps TimeoutException to timeoutError failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType =
              SupabaseExceptionType.timeout;

          final result = await repository.createCostItem(testItem);

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.timeoutError,
            ),
          );
        },
      );

      test(
        'maps SocketException to connectionError failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType =
              SupabaseExceptionType.socket;

          final result = await repository.createCostItem(testItem);

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.connectionError,
            ),
          );
        },
      );

      test(
        'maps TypeError to parsingError failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.type;

          final result = await repository.createCostItem(testItem);

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.parsingError,
            ),
          );
        },
      );

      test(
        'maps unexpected exception to unexpectedError failure',
        () async {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;

          final result = await repository.createCostItem(testItem);

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.unexpectedError,
            ),
          );
        },
      );

    });
  });
}
