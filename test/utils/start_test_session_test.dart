import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_app_bootstrap_factory.dart';
import 'start_test_session.dart';

class _TestModule extends Module {
  @override
  List<Module> get imports => [
    ProjectLibraryModule(
      FakeAppBootstrapFactory.create(
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      ),
    ),
  ];
}

void main() {
  tearDown(Modular.destroy);

  group('startTestSession', () {
    test('adds the per-user objects', () {
      Modular.init(_TestModule());

      startTestSession();

      expect(Modular.tryGet<CurrentProjectNotifier>(), isNotNull);
    });

    test('gives new objects after Modular is set up again', () {
      Modular.init(_TestModule());
      startTestSession();
      final first = Modular.get<CurrentProjectNotifier>();
      first.setCurrentProjectId('project-1');
      Modular.destroy();

      Modular.init(_TestModule());
      startTestSession();

      expect(Modular.get<CurrentProjectNotifier>(), isNot(same(first)));
      expect(Modular.get<CurrentProjectNotifier>().currentProjectId, isNull);
    });
  });
}
