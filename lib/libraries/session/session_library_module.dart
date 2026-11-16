import 'package:construculator/libraries/session/interfaces/session_service.dart';
import 'package:construculator/libraries/session/per_user_registrations.dart';
import 'package:construculator/libraries/session/session_service_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module providing [SessionService].
///
/// Bound as a lazy singleton so the app has one record of whether a session is
/// active.
class SessionLibraryModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<SessionService>(
      () => SessionServiceImpl(registrations: perUserRegistrations),
    );
  }
}
