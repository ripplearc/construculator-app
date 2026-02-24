import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<CurrentProjectNotifier>(
      () => FakeCurrentProjectNotifier(
        initialProjectId: '950e8400-e29b-41d4-a716-446655440001',
      ),
      key: 'fakeCurrentProjectNotifier',
    );
  }
}

void main() {
  late FakeCurrentProjectNotifier fakeNotifier;

  setUp(() {
    Modular.init(_TestModule());
    fakeNotifier =
        Modular.get<CurrentProjectNotifier>(key: 'fakeCurrentProjectNotifier')
            as FakeCurrentProjectNotifier;
  });

  tearDown(() {
    Modular.destroy();
  });

  group('FakeCurrentProjectNotifier', () {
    group('Interface Contract Verification', () {
      test('should implement CurrentProjectNotifier interface', () {
        expect(fakeNotifier, isA<CurrentProjectNotifier>());
      });

      test('should provide setCurrentProjectId method', () {
        expect(
          () => fakeNotifier.setCurrentProjectId('test-project'),
          returnsNormally,
        );
      });
    });

    group('Core Functionality', () {
      test('setCurrentProjectId should update currentProjectId', () {
        const newId = 'new-project-id';

        fakeNotifier.setCurrentProjectId(newId);

        expect(fakeNotifier.currentProjectId, newId);
      });

      test('setCurrentProjectId should emit on stream', () async {
        const newId = 'emitted-project';

        expectLater(fakeNotifier.onCurrentProjectChanged, emits(newId));

        fakeNotifier.setCurrentProjectId(newId);
      });

      test('currentProjectId returns initialProjectId from constructor', () {
        expect(
          fakeNotifier.currentProjectId,
          '950e8400-e29b-41d4-a716-446655440001',
        );
      });
    });

    group('Test Utility Features', () {
      test(
        'should track project id change events for test verification',
        () async {
          fakeNotifier.setCurrentProjectId('first');
          fakeNotifier.setCurrentProjectId('second');
          fakeNotifier.setCurrentProjectId(null);

          // Allow stream to process
          await Future<void>.delayed(Duration.zero);

          expect(fakeNotifier.projectIdChangedEvents, [
            'first',
            'second',
            null,
          ]);
        },
      );

      test('reset should clear tracked events', () async {
        fakeNotifier.setCurrentProjectId('some-id');
        await Future<void>.delayed(Duration.zero);

        fakeNotifier.reset();

        expect(fakeNotifier.projectIdChangedEvents, isEmpty);
        expect(fakeNotifier.currentProjectId, isNull);
      });

      test('reset with projectId should set new projectId', () {
        fakeNotifier.reset(projectId: 'reset-project-id');

        expect(fakeNotifier.currentProjectId, 'reset-project-id');
      });
    });

    group('Broadcast Stream Behavior', () {
      test('should support multiple listeners', () async {
        final listener1Events = <String?>[];
        final listener2Events = <String?>[];

        final sub1 = fakeNotifier.onCurrentProjectChanged.listen(
          listener1Events.add,
        );
        final sub2 = fakeNotifier.onCurrentProjectChanged.listen(
          listener2Events.add,
        );

        fakeNotifier.setCurrentProjectId('shared');

        await Future<void>.delayed(Duration.zero);

        expect(listener1Events, ['shared']);
        expect(listener2Events, ['shared']);

        await sub1.cancel();
        await sub2.cancel();
      });
    });
  });
}
