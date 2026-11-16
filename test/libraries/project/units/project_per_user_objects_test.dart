import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/session/interfaces/session_service.dart';
import 'package:construculator/libraries/session/session_library_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

class _TestModule extends Module {
  final FakeSupabaseWrapper supabaseWrapper;

  _TestModule({required this.supabaseWrapper});

  @override
  List<Module> get imports => [
    SessionLibraryModule(registrations: const [registerProjectPerUserObjects]),
    ProjectLibraryModule(
      FakeAppBootstrapFactory.create(supabaseWrapper: supabaseWrapper),
    ),
  ];
}

void main() {
  late SessionService sessionService;

  setUp(() {
    Modular.init(
      _TestModule(supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl())),
    );
    addTearDown(Modular.destroy);
    sessionService = Modular.get<SessionService>();
    addTearDown(sessionService.endSession);
  });

  group('project per-user objects', () {
    test('are not available before a session starts', () {
      expect(Modular.tryGet<CurrentProjectNotifier>(), isNull);
      expect(Modular.tryGet<ProjectRepository>(), isNull);
    });

    test('are available while a session is active', () {
      sessionService.startSession();

      expect(Modular.tryGet<CurrentProjectNotifier>(), isNotNull);
      expect(Modular.tryGet<ProjectRepository>(), isNotNull);
    });

    test('are gone after the session ends', () {
      sessionService.startSession();
      Modular.get<CurrentProjectNotifier>().setCurrentProjectId('project-1');

      sessionService.endSession();

      expect(Modular.tryGet<CurrentProjectNotifier>(), isNull);
      expect(Modular.tryGet<ProjectRepository>(), isNull);
    });

    test('are new, with no selected project, in the next session', () {
      sessionService.startSession();
      final firstNotifier = Modular.get<CurrentProjectNotifier>();
      final firstRepository = Modular.get<ProjectRepository>();
      firstNotifier.setCurrentProjectId('project-1');
      sessionService.endSession();

      sessionService.startSession();

      expect(Modular.get<CurrentProjectNotifier>(), isNot(same(firstNotifier)));
      expect(Modular.get<ProjectRepository>(), isNot(same(firstRepository)));
      expect(Modular.get<CurrentProjectNotifier>().currentProjectId, isNull);
    });

    test('give one notifier to every reader in a session', () {
      sessionService.startSession();

      expect(
        Modular.get<CurrentProjectNotifier>(),
        same(Modular.get<CurrentProjectNotifier>()),
      );
    });
  });
}
