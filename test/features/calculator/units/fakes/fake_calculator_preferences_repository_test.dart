import 'package:construculator/features/calculator/testing/fake_calculator_preferences_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCalculatorPreferencesRepository repository;

  const metric = CalculatorPreferences(system: MeasurementSystem.metric);

  setUp(() {
    repository = FakeCalculatorPreferencesRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  group('FakeCalculatorPreferencesRepository', () {
    test('starts every watcher on the current settings', () async {
      expect(
        await repository.watchPreferences().first,
        CalculatorPreferences.defaults,
      );
      repository.emit(metric);
      expect(await repository.watchPreferences().first, metric);
    });

    test('a save is seen by watchers and recorded', () async {
      final seen = <CalculatorPreferences>[];
      final subscription = repository.watchPreferences().listen(seen.add);
      addTearDown(subscription.cancel);

      final result = await repository.savePreferences(metric);
      await pumpEventQueue();

      expect(result.fold((_) => null, (saved) => saved), metric);
      expect(repository.savedPreferences, [metric]);
      expect(seen, [CalculatorPreferences.defaults, metric]);
    });

    test('a configured failure is answered and nothing changes', () async {
      repository.saveFailure = UserNotFoundFailure();
      final result = await repository.savePreferences(metric);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<UserNotFoundFailure>(),
      );
      expect(repository.current, CalculatorPreferences.defaults);
      expect(repository.savedPreferences, [metric]);
    });

    test('reset puts it back to a fresh install', () async {
      repository.saveFailure = UserNotFoundFailure();
      await repository.savePreferences(metric);
      repository.reset();
      expect(repository.current, CalculatorPreferences.defaults);
      expect(repository.saveFailure, isNull);
      expect(repository.savedPreferences, isEmpty);
    });

    test('ends its streams on dispose and ignores later emits', () async {
      var done = false;
      repository.watchPreferences().listen((_) {}, onDone: () => done = true);
      repository.dispose();
      await pumpEventQueue();
      expect(done, isTrue);
      repository.emit(metric);
      expect(repository.current, metric);
    });
  });
}
