import 'package:construculator/app/per_user_registrations.dart';
import 'package:construculator/libraries/session/session_module.dart';
import 'package:construculator/libraries/session/session_service_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Adds the real per-user objects to the current `Modular` setup, as a sign-in
/// does in the app. Call it right after `Modular.init` in a test that reads
/// per-user objects.
///
/// `Modular.destroy` does not remove a session module, so this removes any
/// left over from an earlier test first.
void startTestSession() {
  Modular.unbindModule<SessionModule>();
  // ignore: no_direct_instantiation
  SessionServiceImpl(registrations: perUserRegistrations).startSession();
}
