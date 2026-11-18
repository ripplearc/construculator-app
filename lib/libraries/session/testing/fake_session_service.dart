import 'package:construculator/libraries/session/interfaces/session_service.dart';

/// [SessionService] that records the calls and adds no objects.
class FakeSessionService implements SessionService {
  bool _isActive = false;

  /// How many times [startSession] changed the session from ended to started.
  int startCount = 0;

  /// How many times [endSession] changed the session from started to ended.
  int endCount = 0;

  @override
  bool get isActive => _isActive;

  @override
  void startSession() {
    if (_isActive) return;
    _isActive = true;
    startCount++;
  }

  @override
  void endSession() {
    if (!_isActive) return;
    _isActive = false;
    endCount++;
  }
}
