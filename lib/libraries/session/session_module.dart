import 'package:flutter_modular/flutter_modular.dart';

/// Registers one library's per-user objects inside the session.
typedef PerUserRegistration = void Function(Injector i);

/// The objects that exist only while one user is signed in.
///
/// Added with `Modular.bindModule` and removed with `Modular.unbindModule`
/// only. It must never appear in another module's `imports`, because imported
/// modules are never removed.
class SessionModule extends Module {
  /// Registrations that add the per-user objects of each library.
  final List<PerUserRegistration> registrations;

  /// Creates a [SessionModule] holding the objects that [registrations] add.
  SessionModule({required this.registrations});

  @override
  void binds(Injector i) {
    for (final register in registrations) {
      register(i);
    }
  }
}
