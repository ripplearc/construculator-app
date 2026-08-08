// coverage:ignore-file
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CalculatorTestModule extends Module {
  @override
  void binds(Injector i) {
    i.add<CalculatorBloc>(() => CalculatorBloc());
  }
}
