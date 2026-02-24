import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/project/data/current_project_notifier_impl.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestModule extends Module {
  final AppBootstrap appBootstrap;
  _TestModule(this.appBootstrap);

  @override
  List<Module> get imports => [ProjectLibraryModule(appBootstrap)];
}

void main() {
  group('CurrentProjectNotifierImpl', () {
    late CurrentProjectNotifierImpl notifier;
    late AppBootstrap appBootstrap;

    setUpAll(() {
      appBootstrap = AppBootstrap(
        envLoader: FakeEnvLoader(),
        config: FakeAppConfig(),
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      );
      Modular.init(_TestModule(appBootstrap));
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      notifier =
          Modular.get<CurrentProjectNotifier>() as CurrentProjectNotifierImpl;
      // Reset state for each test since the same singleton instance is shared
      notifier.setCurrentProjectId('950e8400-e29b-41d4-a716-446655440001');
    });

    group('constructor', () {
      test('initializes with default projectId', () {
        expect(
          notifier.currentProjectId,
          '950e8400-e29b-41d4-a716-446655440001',
        );
      });
    });

    group('setCurrentProjectId', () {
      test('updates currentProjectId', () {
        const newId = 'new-project-456';

        notifier.setCurrentProjectId(newId);

        expect(notifier.currentProjectId, newId);
      });

      test('updates currentProjectId to null', () {
        notifier.setCurrentProjectId(null);

        expect(notifier.currentProjectId, isNull);
      });

      test('emits new projectId on onCurrentProjectChanged stream', () async {
        const newId = 'emitted-project-789';

        expectLater(notifier.onCurrentProjectChanged, emits(newId));

        notifier.setCurrentProjectId(newId);
      });

      test('emits each projectId change sequentially', () async {
        expectLater(
          notifier.onCurrentProjectChanged,
          emitsInOrder(['first', 'second', null, 'third']),
        );

        notifier.setCurrentProjectId('first');
        notifier.setCurrentProjectId('second');
        notifier.setCurrentProjectId(null);
        notifier.setCurrentProjectId('third');
      });
    });

    group('onCurrentProjectChanged', () {
      test('is a broadcast stream allowing multiple listeners', () async {
        expectLater(notifier.onCurrentProjectChanged, emits('shared-event'));
        expectLater(notifier.onCurrentProjectChanged, emits('shared-event'));

        notifier.setCurrentProjectId('shared-event');
      });

      test('does not emit initial value on subscribe', () async {
        final emittedIds = <String?>[];
        final subscription = notifier.onCurrentProjectChanged.listen(
          emittedIds.add,
        );

        expect(emittedIds, isEmpty);

        await subscription.cancel();
      });
    });

    group('dispose', () {
      test('closes stream and prevents further emissions', () async {
        var errorOccurred = false;
        final subscription = notifier.onCurrentProjectChanged.listen(
          (_) {},
          onError: (_) => errorOccurred = true,
          onDone: () {},
        );

        notifier.dispose();

        expect(
          () => notifier.setCurrentProjectId('after-dispose'),
          throwsA(anything),
        );

        await subscription.cancel();
        expect(errorOccurred, isFalse);
      });
    });
  });
}
