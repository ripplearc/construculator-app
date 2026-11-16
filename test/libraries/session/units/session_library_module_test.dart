import 'package:construculator/libraries/session/interfaces/session_service.dart';
import 'package:construculator/libraries/session/session_library_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _PerUserObject {}

void _registerPerUserObject(Injector i) {
  i.addLazySingleton(_PerUserObject.new);
}

class _TestModule extends Module {
  @override
  List<Module> get imports => [
    SessionLibraryModule(registrations: const [_registerPerUserObject]),
  ];
}

void main() {
  setUp(() {
    Modular.init(_TestModule());
    addTearDown(Modular.destroy);
  });

  group('SessionLibraryModule', () {
    test('starts with no session', () {
      expect(Modular.get<SessionService>().isActive, isFalse);
    });

    test('binds one shared SessionService', () {
      expect(
        Modular.get<SessionService>(),
        same(Modular.get<SessionService>()),
      );
    });

    test('starts and ends a session through the shared service', () {
      final service = Modular.get<SessionService>();

      service.startSession();
      expect(Modular.get<SessionService>().isActive, isTrue);

      service.endSession();
      expect(Modular.get<SessionService>().isActive, isFalse);
    });

    test('adds the registrations it was given when a session starts', () {
      final service = Modular.get<SessionService>();
      expect(Modular.tryGet<_PerUserObject>(), isNull);

      service.startSession();
      addTearDown(service.endSession);

      expect(Modular.tryGet<_PerUserObject>(), isNotNull);
    });
  });
}
