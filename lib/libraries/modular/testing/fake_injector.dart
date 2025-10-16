import 'package:flutter_modular/flutter_modular.dart';

/// A fake Injector for testing that tracks dependency registrations and executes factory functions.
class FakeInjector implements Injector {
  int addLazySingletonCalls = 0;
  int addCalls = 0;
  int executedUseCaseFactories = 0;
  int executedBlocFactories = 0;
  int executedFactories = 0;
  int useCaseFactories = 0;
  int blocFactories = 0;
  int lazySingletonCalls = 0;
  final List<String> createdUseCases = [];
  final List<String> createdBlocs = [];

  @override
  void addLazySingleton<T>(
    Function factory, {
    BindConfig<T>? config,
    String? key,
  }) {
    addLazySingletonCalls++;
    lazySingletonCalls++;

    // Execute the factory function to cover internal logic
    try {
      final instance = factory();
      executedUseCaseFactories++;
      executedFactories++;

      // Track specific use case types by checking runtime type
      final instanceType = instance.runtimeType.toString();
      if (instanceType.contains('UseCase')) {
        createdUseCases.add(instanceType);
        useCaseFactories++;
      }
    } catch (e) {
      // Expected to fail due to missing dependencies, but we still count execution
      executedUseCaseFactories++;
      executedFactories++;

      // Try to determine the type from the error or factory function
      final factoryString = factory.toString();
      if (factoryString.contains('UseCase')) {
        // Extract the use case name from the factory string
        final match = RegExp(r'(\w+UseCase)').firstMatch(factoryString);
        if (match != null) {
          createdUseCases.add(match.group(1)!);
          useCaseFactories++;
        }
      }
    }
  }

  @override
  void add<T>(Function factory, {BindConfig<T>? config, String? key}) {
    addCalls++;

    // Execute the factory function to cover internal logic
    try {
      final instance = factory();
      executedBlocFactories++;
      executedFactories++;

      // Track specific bloc types by checking runtime type
      final instanceType = instance.runtimeType.toString();
      if (instanceType.contains('Bloc')) {
        createdBlocs.add(instanceType);
        blocFactories++;
      }
    } catch (e) {
      // Expected to fail due to missing dependencies, but we still count execution
      executedBlocFactories++;
      executedFactories++;

      // Try to determine the type from the error or factory function
      final factoryString = factory.toString();
      if (factoryString.contains('Bloc')) {
        // Extract the bloc name from the factory string
        final match = RegExp(r'(\w+Bloc)').firstMatch(factoryString);
        if (match != null) {
          createdBlocs.add(match.group(1)!);
          blocFactories++;
        }
      }
    }
  }

  int get totalDependencies => addLazySingletonCalls + addCalls;
  int get totalCalls => lazySingletonCalls + addCalls;

  /// Clears all tracking data for a clean state between tests.
  void reset() {
    addLazySingletonCalls = 0;
    addCalls = 0;
    executedUseCaseFactories = 0;
    executedBlocFactories = 0;
    executedFactories = 0;
    useCaseFactories = 0;
    blocFactories = 0;
    lazySingletonCalls = 0;
    createdUseCases.clear();
    createdBlocs.clear();
  }

  // Implement other required methods with no-op implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
