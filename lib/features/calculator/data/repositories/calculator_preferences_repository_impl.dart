import 'dart:async';

import 'package:construculator/features/calculator/data/models/calculator_preferences_dto.dart';
import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// [CalculatorPreferencesRepository] over the signed-in profile: the
/// settings live under the `calculator` key of `users.user_preferences`,
/// which the auth library already reads and writes as a whole and
/// PowerSync already syncs, so there is no table, no query and no second
/// sync path here.
///
/// ## The profile stream is the source of truth
///
/// [watchPreferences] is the profile stream mapped through the DTO, so a
/// setting changed on another device arrives the way any profile change
/// does, and a save is visible to every watcher because
/// `AuthManager.updateUserProfile` re-emits the profile. The stream only
/// announces changes, so the profile already signed in when the first
/// watcher or save arrives is fetched once through the auth manager, the
/// way the dashboard starts. The last profile seen is kept so that a save
/// can rewrite the whole `user_preferences` map without a read: other keys
/// under it (theme, units…) are carried over untouched.
///
/// Every stream handed out adds the current settings first, so a new
/// watcher renders at once where a broadcast controller alone would leave
/// it waiting for the next change, and takes its subscription inside the
/// listen callback, so no change can fall between that first value and the
/// rest. The profile is followed once, on the first watch or save; a
/// repository created after sign-in would otherwise never hear of the
/// profile until its next change.
class CalculatorPreferencesRepositoryImpl
    implements CalculatorPreferencesRepository {
  static final _logger = AppLogger().tag('CalculatorPreferencesRepositoryImpl');

  final AuthNotifier _authNotifier;
  final AuthManager _authManager;
  final _preferences = StreamController<CalculatorPreferences>.broadcast();

  StreamSubscription<User?>? _profileSubscription;
  User? _user;
  CalculatorPreferences _current = CalculatorPreferences.defaults;
  bool _isDisposed = false;

  CalculatorPreferencesRepositoryImpl({
    required this._authNotifier,
    required this._authManager,
  });

  @override
  Stream<CalculatorPreferences> watchPreferences() {
    _followProfile();
    return Stream<CalculatorPreferences>.multi((controller) {
      controller.add(_current);
      final subscription = _preferences.stream.listen(
        controller.add,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    }).distinct();
  }

  @override
  Future<Either<Failure, CalculatorPreferences>> savePreferences(
    CalculatorPreferences preferences,
  ) async {
    _followProfile();
    final user = _user ?? await _loadSignedInProfile();
    if (user == null) {
      _logger.warning('No signed-in profile to save calculator preferences to');
      return Left(UserNotFoundFailure());
    }
    final updated = user.copyWith(
      userPreferences: {
        ...user.userPreferences,
        CalculatorPreferencesDto.preferencesKey: CalculatorPreferencesDto(
          preferences,
        ).toJson(),
      },
    );
    final result = await _authManager.updateUserProfile(updated);
    if (!result.isSuccess) {
      final errorType = result.errorType ?? AuthErrorType.serverError;
      _logger.warning('Saving calculator preferences failed: $errorType');
      return Left(AuthFailure(errorType: errorType));
    }
    if (result.data == null) {
      _logger.warning('No profile row to save calculator preferences to');
      return Left(UserNotFoundFailure());
    }
    return Right(preferences);
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_profileSubscription?.cancel());
    _profileSubscription = null;
    unawaited(_preferences.close());
  }

  void _followProfile() {
    if (_isDisposed || _profileSubscription != null) return;
    _profileSubscription = _authNotifier.onUserProfileChanged.listen(
      _onProfileChanged,
    );
    unawaited(_loadSignedInProfile());
  }

  Future<User?> _loadSignedInProfile() async {
    final credentialId = _authManager.getCurrentCredentials().data?.id;
    if (credentialId == null || credentialId.isEmpty) return null;
    final result = await _authManager.getUserProfile(credentialId);
    if (!result.isSuccess) return null;
    _onProfileChanged(result.data);
    return result.data;
  }

  void _onProfileChanged(User? user) {
    if (_isDisposed) return;
    _user = user;
    _current = CalculatorPreferencesDto.fromJson(
      user?.userPreferences[CalculatorPreferencesDto.preferencesKey],
    ).preferences;
    _preferences.add(_current);
  }
}
