import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorBloc', () {
    late CalculatorBloc bloc;

    setUp(() {
      Modular.init(CalculatorModule());
      bloc = Modular.get<CalculatorBloc>();
    });

    tearDown(() async {
      await bloc.close();
      Modular.destroy();
    });

    test('initial state is CalculatorState.initial()', () {
      expect(bloc.state, equals(CalculatorState.initial()));
    });
  });
}
