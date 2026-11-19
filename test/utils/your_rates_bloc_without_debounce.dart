import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// A [YourRatesBloc] wired like the module's, but with no search debounce, so
/// a widget test sees a search's rows once the frame settles instead of
/// pumping past the 300 ms wait.
// ignore: no_direct_instantiation, reason: needs queryDebounce: Duration.zero, which Modular's registration can't supply per-test
YourRatesBloc yourRatesBlocWithoutDebounce() => YourRatesBloc(
  repository: Modular.get<YourRatesRepository>(),
  companyResolver: Modular.get<CurrentCompanyResolver>(),
  clock: Modular.get<Clock>(),
  queryDebounce: Duration.zero,
);
