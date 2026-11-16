import 'package:construculator/libraries/session/interfaces/session_service.dart';
import 'package:construculator/libraries/session/session_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// [SessionService] that adds and removes [SessionModule] at runtime.
class SessionServiceImpl implements SessionService {
  final List<PerUserRegistration> _registrations;
  bool _isActive = false;

  /// Creates a [SessionServiceImpl] whose session holds the objects that
  /// [_registrations] add.
  SessionServiceImpl({required this._registrations});

  @override
  bool get isActive => _isActive;

  @override
  void startSession() {
    if (_isActive) return;
    Modular.bindModule(SessionModule(registrations: _registrations));
    _isActive = true;
  }

  @override
  void endSession() {
    if (!_isActive) return;
    Modular.unbindModule<SessionModule>();
    _isActive = false;
  }
}
