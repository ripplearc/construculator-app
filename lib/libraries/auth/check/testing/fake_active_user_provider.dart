import 'package:construculator/libraries/auth/check/interfaces/check_finished_state.dart';

/// [ActiveUserProvider] that is always finished and reports the user a
/// function returns at the time of the call.
class FakeActiveUserProvider implements ActiveUserProvider {
  final String? Function() _userIdOf;

  /// Reports the user that [userIdOf] returns, or nobody when it returns null.
  FakeActiveUserProvider({required this._userIdOf});

  @override
  String? get activeUserId => _userIdOf();

  @override
  Future<String?> whenFinished() async => _userIdOf();

  @override
  Future<bool> whenFinishedFor(String userId) async => _userIdOf() == userId;
}
