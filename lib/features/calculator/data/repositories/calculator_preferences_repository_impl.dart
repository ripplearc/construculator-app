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
///
/// ## The first fetch never overwrites a newer profile
///
/// The fetch of the profile already signed in is shared: a save that
/// arrives before it finishes waits for the same fetch instead of starting
/// a second one. Its result is applied only if no profile was announced
/// while it ran, since it may be older than that announcement. As it
/// returns, `AuthManager.getUserProfile` also announces what it fetched on
/// `onUserProfileChanged`; that echo is dropped once, so it cannot bring
/// the older profile back either. A setting changed while a slow fetch was
/// running is never put back, and the next save never writes back older
/// keys.
class CalculatorPreferencesRepositoryImpl
    implements CalculatorPreferencesRepository {
  static final _logger = AppLogger().tag('CalculatorPreferencesRepositoryImpl');

  final AuthNotifier _authNotifier;
  final AuthManager _authManager;
  final _preferences = StreamController<CalculatorPreferences>.broadcast();

  StreamSubscription<User?>? _profileSubscription;
  Future<void>? _signedInProfileFetch;
  User? _fetchEcho;
  int _profileVersion = 0;
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
    if (_user == null) await _loadSignedInProfile();
    final user = _user;
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
      _onProfileAnnounced,
    );
    unawaited(_loadSignedInProfile());
  }

  void _onProfileAnnounced(User? user) {
    if (user != null && identical(user, _fetchEcho)) {
      _fetchEcho = null;
      return;
    }
    _profileVersion++;
    _onProfileChanged(user);
  }

  Future<void> _loadSignedInProfile() {
    if (_signedInProfileFetch case final inFlight?) return inFlight;
    final credentialId = _authManager.getCurrentCredentials().data?.id;
    if (credentialId == null || credentialId.isEmpty) return Future.value();
    return _signedInProfileFetch = _fetchSignedInProfile(credentialId);
  }

  Future<void> _fetchSignedInProfile(String credentialId) async {
    final versionAtStart = _profileVersion;
    final result = await _authManager.getUserProfile(credentialId);
    _signedInProfileFetch = null;
    if (!result.isSuccess) return;
    _fetchEcho = result.data;
    if (_profileVersion == versionAtStart) _onProfileChanged(result.data);
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
