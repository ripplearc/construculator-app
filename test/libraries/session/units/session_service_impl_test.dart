import 'package:construculator/libraries/session/session_module.dart';
import 'package:construculator/libraries/session/session_service_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _PerUserObject implements Disposable {
  bool isDisposed = false;

  @override
  void dispose() => isDisposed = true;
}

class _HoldsPerUserObject {
  final _PerUserObject perUserObject;

  _HoldsPerUserObject(this.perUserObject);
}

class _RootModule extends Module {}

void registerPerUserObjects(Injector i) {
  i.addLazySingleton<_PerUserObject>(_PerUserObject.new);
  i.addLazySingleton<_HoldsPerUserObject>(_HoldsPerUserObject.new);
}

SessionServiceImpl createService(List<PerUserRegistration> registrations) {
  // ignore: no_direct_instantiation
  return SessionServiceImpl(registrations: registrations);
}

void main() {
  late SessionServiceImpl service;

  setUp(() {
    Modular.init(_RootModule());
    service = createService([registerPerUserObjects]);
    addTearDown(() {
      service.endSession();
      Modular.destroy();
    });
  });

  group('SessionServiceImpl', () {
    test('has no session before it is started', () {
      expect(service.isActive, isFalse);
      expect(Modular.tryGet<_PerUserObject>(), isNull);
    });

    test('makes the registered objects available once started', () {
      service.startSession();

      expect(service.isActive, isTrue);
      expect(Modular.get<_PerUserObject>().isDisposed, isFalse);
    });

    test('removes and disposes the objects when the session ends', () {
      service.startSession();
      final perUserObject = Modular.get<_PerUserObject>();

      service.endSession();

      expect(service.isActive, isFalse);
      expect(perUserObject.isDisposed, isTrue);
      expect(Modular.tryGet<_PerUserObject>(), isNull);
    });

    test('gives the next session new objects', () {
      service.startSession();
      final first = Modular.get<_PerUserObject>();
      service.endSession();

      service.startSession();
      final second = Modular.get<_PerUserObject>();

      expect(second, isNot(same(first)));
      expect(second.isDisposed, isFalse);
    });

    test('leaves a kept reference pointing at the disposed object', () {
      service.startSession();
      final kept = Modular.get<_HoldsPerUserObject>();
      service.endSession();
      service.startSession();

      expect(kept.perUserObject.isDisposed, isTrue);
      expect(
        Modular.get<_HoldsPerUserObject>().perUserObject,
        isNot(same(kept.perUserObject)),
      );
    });

    test('keeps the same objects when started twice', () {
      service.startSession();
      final first = Modular.get<_PerUserObject>();

      service.startSession();

      expect(Modular.get<_PerUserObject>(), same(first));
      expect(first.isDisposed, isFalse);
    });

    test('does nothing when ended without a session', () {
      service.endSession();

      expect(service.isActive, isFalse);
    });

    test('adds the objects of every registration', () {
      service = createService([
        registerPerUserObjects,
        (i) => i.addLazySingleton<_OtherObject>(_OtherObject.new),
      ]);

      service.startSession();

      expect(Modular.get<_PerUserObject>(), isA<_PerUserObject>());
      expect(Modular.get<_OtherObject>(), isA<_OtherObject>());
    });
  });
}

class _OtherObject {}
