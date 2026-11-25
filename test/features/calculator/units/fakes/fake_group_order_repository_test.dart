import 'package:async/async.dart';
import 'package:construculator/features/calculator/testing/fake_group_order_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaults = ['Basic Geometry', 'Shapes', 'Materials', 'Unit', 'Trig'];
  const unitFirst = ['Unit', 'Basic Geometry', 'Shapes', 'Materials', 'Trig'];
  late FakeGroupOrderRepository repository;

  setUp(() {
    repository = FakeGroupOrderRepository(defaultOrder: defaults);
  });

  tearDown(() {
    repository.dispose();
  });

  group('FakeGroupOrderRepository', () {
    test('shows the default until an order is saved, then the saved one, and '
        'the watch follows a save, a repeat and a reset', () async {
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final events = StreamQueue(repository.watchGroupOrder());
      expect(await events.next, defaults);
      await repository.saveGroupOrder(unitFirst);
      expect(await events.next, unitFirst);
      expect(repository.saved, unitFirst);
      expect(repository.saveCallCount, 1);
      await repository.saveGroupOrder(unitFirst);
      repository.reset();
      expect(await events.next, defaults);
      expect(repository.saveCallCount, 0);
      await events.cancel();
    });

    test('a save failure refuses the save and keeps the order', () async {
      repository.saveFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );
      final result = await repository.saveGroupOrder(unitFirst);
      expect(result.isLeft(), isTrue);
      expect(repository.saved, isNull);
      expect(await repository.watchGroupOrder().first, defaults);
    });

    test('a save and a watch after dispose do not throw: the save is kept '
        'and the watch answers once and ends', () async {
      repository.dispose();
      expect(
        await repository.saveGroupOrder(unitFirst),
        isA<Right<Object?, Object?>>(),
      );
      expect(repository.saved, unitFirst);
      expect(await repository.watchGroupOrder().toList(), [unitFirst]);
    });
  });
}
