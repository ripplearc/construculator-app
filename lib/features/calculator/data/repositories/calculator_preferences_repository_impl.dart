import 'dart:async';

import 'package:construculator/features/calculator/data/models/calculator_preferences_dto.dart';
import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
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
/// keys. A fetch that fails is not kept: the next save fetches again and,
/// if that fails too, answers with the auth library's error type rather
/// than "no profile".
///
/// ## Sign-out and a user switch
///
/// A sign-out announces no profile — the dashboard reads a `null` profile
/// as "create an account" — so it is heard on `onAuthStateChanged` instead.
/// An unauthenticated state, or an authenticated one for a credential other
/// than the one the held or in-flight profile belongs to, forgets that
/// profile: every watcher falls back to the defaults, a fetch still in
/// flight is dropped, and the next watch or save fetches the profile of
/// whoever is signed in by then. A save checks the signed-in credential
/// itself as well, because the auth state is delivered a tick after it
/// changes, so the previous user's row is never written. A lost connection
/// says nothing about who is signed in and is ignored.
class CalculatorPreferencesRepositoryImpl
    implements CalculatorPreferencesRepository {
  static final _logger = AppLogger().tag('CalculatorPreferencesRepositoryImpl');

  final AuthNotifier _authNotifier;
  final AuthManager _authManager;
  final _preferences = StreamController<CalculatorPreferences>.broadcast();

  StreamSubscription<User?>? _profileSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  ({String credentialId, Future<AuthErrorType?> result})? _signedInProfileFetch;
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
    final credentials = _authManager.getCurrentCredentials();
    if (credentials.isSuccess &&
        credentials.data?.id != _followedCredentialId) {
      _forgetProfile();
    }
    if (_user == null) {
      final fetchError = await _loadSignedInProfile();
      if (fetchError != null) {
        _logger.warning(
          'Saving calculator preferences failed: the signed-in profile could '
          'not be read ($fetchError)',
        );
        return Left(AuthFailure(errorType: fetchError));
      }
    }
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
    // TODO: [CA-1224] Write the calculator key with a server-side JSON merge:
    // this sends the whole row built from the last profile seen, so a key
    // another device changed since then is written back.
    // https://ripplearc.youtrack.cloud/issue/CA-1224
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
    unawaited(_authStateSubscription?.cancel());
    _profileSubscription = null;
    _authStateSubscription = null;
    unawaited(_preferences.close());
  }

  String? get _followedCredentialId =>
      _user?.credentialId ?? _signedInProfileFetch?.credentialId;

  void _followProfile() {
    if (_isDisposed || _profileSubscription != null) return;
    _profileSubscription = _authNotifier.onUserProfileChanged.listen(
      _onProfileAnnounced,
    );
    _authStateSubscription = _authNotifier.onAuthStateChanged.listen(
      _onAuthStateChanged,
    );
    unawaited(_loadSignedInProfile());
  }

  void _onAuthStateChanged(AuthState state) {
    if (state.status == AuthStatus.connectionError) return;
    if (state.user?.id != _followedCredentialId) _forgetProfile();
  }

  void _forgetProfile() {
    _profileVersion++;
    _signedInProfileFetch = null;
    _onProfileChanged(null);
  }

  void _onProfileAnnounced(User? user) {
    if (user != null && identical(user, _fetchEcho)) {
      _fetchEcho = null;
      return;
    }
    _profileVersion++;
    _onProfileChanged(user);
  }

  Future<AuthErrorType?> _loadSignedInProfile() {
    if (_signedInProfileFetch case final inFlight?) return inFlight.result;
    final credentialId = _authManager.getCurrentCredentials().data?.id;
    if (credentialId == null || credentialId.isEmpty) return Future.value();
    final fetch = _fetchSignedInProfile(credentialId);
    _signedInProfileFetch = (credentialId: credentialId, result: fetch);
    return fetch.whenComplete(() {
      // A sign-out meanwhile may have put the next user's fetch on record.
      if (identical(_signedInProfileFetch?.result, fetch)) {
        _signedInProfileFetch = null;
      }
    });
  }

  Future<AuthErrorType?> _fetchSignedInProfile(String credentialId) async {
    final versionAtStart = _profileVersion;
    final result = await _authManager.getUserProfile(credentialId);
    if (!result.isSuccess) return result.errorType ?? AuthErrorType.serverError;
    _fetchEcho = result.data;
    if (_profileVersion == versionAtStart) _onProfileChanged(result.data);
    return null;
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
