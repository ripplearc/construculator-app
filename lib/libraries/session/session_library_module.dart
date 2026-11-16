import 'package:construculator/libraries/session/interfaces/session_service.dart';
import 'package:construculator/libraries/session/session_module.dart';
import 'package:construculator/libraries/session/session_service_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module providing [SessionService].
///
/// Bound as a lazy singleton so the app has one record of whether a session is
/// active.
class SessionLibraryModule extends Module {
  /// The registrations that add the per-user objects while a session is
  /// active.
  final List<PerUserRegistration> registrations;

  /// Creates a [SessionLibraryModule] whose service adds [registrations] at
  /// the start of every session.
  SessionLibraryModule({required this.registrations});

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<SessionService>(
      () => SessionServiceImpl(registrations: registrations),
    );
  }
}
