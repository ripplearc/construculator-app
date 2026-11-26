import 'package:construculator/features/calculator/domain/usecases/add_material_size_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/delete_calculation_session_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/delete_material_size_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_material_counts_usecase.dart';
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/testing/fake_trade_stores_repository.dart';
import 'package:construculator/libraries/calculation/testing/fake_calculation_session_repository.dart';

/// A bloc as the page's factory builds one, over [stores] — a fake
/// trade-stores repository showing Appendix B's defaults unless the test
/// hands in its own — so the page and replay tests see the sheet counts
/// the module's chain would read, with no database behind them. Undo takes
/// a banked tape out of [history], the calculation library's fake, which a
/// test hands in to read what is left.
CalculatorBloc calculatorBlocForTests({
  FakeTradeStoresRepository? stores,
  FakeCalculationSessionRepository? history,
}) {
  final repository = stores ?? FakeTradeStoresRepository();
  final sessions = history ?? FakeCalculationSessionRepository();
  // ignore: no_direct_instantiation
  return CalculatorBloc(
    // ignore: no_direct_instantiation
    materialCounts: WatchMaterialCountsUseCase(repository: repository),
    // ignore: no_direct_instantiation
    deleteMaterialSize: DeleteMaterialSizeUseCase(repository: repository),
    // ignore: no_direct_instantiation
    addMaterialSize: AddMaterialSizeUseCase(repository: repository),
    // ignore: no_direct_instantiation
    deleteSession: DeleteCalculationSessionUseCase(repository: sessions),
  );
}
