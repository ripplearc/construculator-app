import 'package:construculator/app/per_user_registrations.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/project/domain/usecases/get_project_header_usecase.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/session/interfaces/session_service.dart';
import 'package:construculator/libraries/session/session_service_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_app_bootstrap_factory.dart';

class _TestModule extends Module {
  _TestModule();

  @override
  List<Module> get imports {
    final bootstrap = FakeAppBootstrapFactory.create();
    return [
      DashboardModule(bootstrap),
      ProjectModule(bootstrap),
      EstimationModule(bootstrap),
    ];
  }
}

void main() {
  late SessionService sessionService;

  setUp(() {
    Modular.init(_TestModule());
    // ignore: no_direct_instantiation
    sessionService = SessionServiceImpl(registrations: perUserRegistrations);
    addTearDown(sessionService.endSession);
    addTearDown(Modular.destroy);
  });

  group('per-user registrations', () {
    test('add no objects before a session starts', () {
      expect(Modular.tryGet<CurrentProjectNotifier>(), isNull);
      expect(Modular.tryGet<ProjectRepository>(), isNull);
      expect(Modular.tryGet<ProjectDropdownBloc>(), isNull);
      expect(Modular.tryGet<GetProjectHeaderUseCase>(), isNull);
      expect(Modular.tryGet<AddCostEstimationUseCase>(), isNull);
    });

    test('add the project, dashboard, header and estimation objects', () {
      sessionService.startSession();

      expect(Modular.tryGet<CurrentProjectNotifier>(), isNotNull);
      expect(Modular.tryGet<ProjectRepository>(), isNotNull);
      expect(Modular.tryGet<ProjectDropdownBloc>(), isNotNull);
      expect(Modular.tryGet<GetProjectHeaderUseCase>(), isNotNull);
      expect(Modular.tryGet<AddCostEstimationUseCase>(), isNotNull);
    });

    test('remove every object when the session ends', () {
      sessionService.startSession();
      Modular.get<ProjectDropdownBloc>();
      Modular.get<GetProjectHeaderUseCase>();
      Modular.get<AddCostEstimationUseCase>();

      sessionService.endSession();

      expect(Modular.tryGet<CurrentProjectNotifier>(), isNull);
      expect(Modular.tryGet<ProjectRepository>(), isNull);
      expect(Modular.tryGet<ProjectDropdownBloc>(), isNull);
      expect(Modular.tryGet<GetProjectHeaderUseCase>(), isNull);
      expect(Modular.tryGet<AddCostEstimationUseCase>(), isNull);
    });

    test('close the project dropdown when the session ends', () {
      sessionService.startSession();
      final dropdown = Modular.get<ProjectDropdownBloc>();

      sessionService.endSession();

      expect(dropdown.isClosed, isTrue);
    });

    test('build new objects for the next session', () {
      sessionService.startSession();
      final dropdown = Modular.get<ProjectDropdownBloc>();
      final header = Modular.get<GetProjectHeaderUseCase>();
      final addUseCase = Modular.get<AddCostEstimationUseCase>();
      Modular.get<CurrentProjectNotifier>().setCurrentProjectId('project-1');
      sessionService.endSession();

      sessionService.startSession();

      expect(Modular.get<ProjectDropdownBloc>(), isNot(same(dropdown)));
      expect(Modular.get<GetProjectHeaderUseCase>(), isNot(same(header)));
      expect(Modular.get<AddCostEstimationUseCase>(), isNot(same(addUseCase)));
      expect(Modular.get<CurrentProjectNotifier>().currentProjectId, isNull);
    });
  });
}
