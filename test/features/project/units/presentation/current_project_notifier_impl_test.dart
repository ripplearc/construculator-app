import 'package:construculator/features/project/presentation/current_project_notifier_impl.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _CurrentProjectNotifierTestModule extends Module {
  final String? initialProjectId;

  _CurrentProjectNotifierTestModule({this.initialProjectId});

  @override
  void binds(Injector i) {
    i.add<CurrentProjectNotifier>(
      () => CurrentProjectNotifierImpl(initialProjectId: initialProjectId),
    );
  }
}

void main() {
  group('CurrentProjectNotifierImpl', () {
    late CurrentProjectNotifierImpl notifier;

    tearDown(() {
      notifier.dispose();
      Modular.destroy();
    });

    group('constructor', () {
      test(
        'initializes with null projectId when no initialProjectId provided',
        () {
          Modular.init(_CurrentProjectNotifierTestModule());
          notifier =
              Modular.get<CurrentProjectNotifier>()
                  as CurrentProjectNotifierImpl;

          expect(notifier.currentProjectId, isNull);
        },
      );

      test('initializes with provided initialProjectId', () {
        const testId = 'test-project-123';
        Modular.init(
          _CurrentProjectNotifierTestModule(initialProjectId: testId),
        );
        notifier =
            Modular.get<CurrentProjectNotifier>() as CurrentProjectNotifierImpl;

        expect(notifier.currentProjectId, testId);
      });
    });

    group('setCurrentProjectId', () {
      setUp(() {
        Modular.init(_CurrentProjectNotifierTestModule());
        notifier =
            Modular.get<CurrentProjectNotifier>() as CurrentProjectNotifierImpl;
      });

      test('updates currentProjectId', () {
        const newId = 'new-project-456';

        notifier.setCurrentProjectId(newId);

        expect(notifier.currentProjectId, newId);
      });

      test('updates currentProjectId to null', () {
        Modular.destroy();
        Modular.init(
          _CurrentProjectNotifierTestModule(initialProjectId: 'initial-id'),
        );
        notifier =
            Modular.get<CurrentProjectNotifier>() as CurrentProjectNotifierImpl;

        notifier.setCurrentProjectId(null);

        expect(notifier.currentProjectId, isNull);
      });

      test('emits new projectId on onCurrentProjectChanged stream', () async {
        const newId = 'emitted-project-789';

        final emittedIds = <String?>[];
        final subscription = notifier.onCurrentProjectChanged.listen(
          emittedIds.add,
        );

        notifier.setCurrentProjectId(newId);

        // Allow stream to emit
        await Future<void>.delayed(Duration.zero);

        expect(emittedIds, [newId]);

        await subscription.cancel();
      });

      test('emits each projectId change sequentially', () async {
        final emittedIds = <String?>[];
        final subscription = notifier.onCurrentProjectChanged.listen(
          emittedIds.add,
        );

        notifier.setCurrentProjectId('first');
        notifier.setCurrentProjectId('second');
        notifier.setCurrentProjectId(null);
        notifier.setCurrentProjectId('third');

        // Allow stream to emit
        await Future<void>.delayed(Duration.zero);

        expect(emittedIds, ['first', 'second', null, 'third']);

        await subscription.cancel();
      });
    });

    group('onCurrentProjectChanged', () {
      setUp(() {
        Modular.init(_CurrentProjectNotifierTestModule());
        notifier =
            Modular.get<CurrentProjectNotifier>() as CurrentProjectNotifierImpl;
      });

      test('is a broadcast stream allowing multiple listeners', () async {
        final listener1Events = <String?>[];
        final listener2Events = <String?>[];

        final sub1 = notifier.onCurrentProjectChanged.listen(
          listener1Events.add,
        );
        final sub2 = notifier.onCurrentProjectChanged.listen(
          listener2Events.add,
        );

        notifier.setCurrentProjectId('shared-event');

        await Future<void>.delayed(Duration.zero);

        expect(listener1Events, ['shared-event']);
        expect(listener2Events, ['shared-event']);

        await sub1.cancel();
        await sub2.cancel();
      });

      test('does not emit initial value on subscribe', () async {
        Modular.destroy();
        Modular.init(
          _CurrentProjectNotifierTestModule(initialProjectId: 'existing'),
        );
        notifier =
            Modular.get<CurrentProjectNotifier>() as CurrentProjectNotifierImpl;

        final emittedIds = <String?>[];
        final subscription = notifier.onCurrentProjectChanged.listen(
          emittedIds.add,
        );

        // Allow potential emissions
        await Future<void>.delayed(Duration.zero);

        expect(emittedIds, isEmpty);

        await subscription.cancel();
      });
    });

    group('dispose', () {
      test('closes stream and prevents further emissions', () async {
        Modular.init(_CurrentProjectNotifierTestModule());
        notifier =
            Modular.get<CurrentProjectNotifier>() as CurrentProjectNotifierImpl;

        var errorOccurred = false;
        final subscription = notifier.onCurrentProjectChanged.listen(
          (_) {},
          onError: (_) => errorOccurred = true,
          onDone: () {},
        );

        notifier.dispose();

        // Stream should be closed; setting project should not cause issues
        // but also should not emit
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
