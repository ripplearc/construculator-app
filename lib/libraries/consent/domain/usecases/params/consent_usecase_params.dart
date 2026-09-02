import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:equatable/equatable.dart';

/// Parameters for the consent status use cases.
///
/// Shared by reading, observing and verifying, which all ask the same single
/// question of the same type.
///
/// Carries the type rather than defaulting to it, because the two consent
/// types are read by different callers for different reasons: the route guard
/// asks about [ConsentType.termsAndPrivacy], analytics capture asks about
/// [ConsentType.analytics], and conflating them would let an analytics opt-out
/// block the app.
class ConsentStatusParams extends Equatable {
  /// Which consent to resolve.
  final ConsentType consentType;

  const ConsentStatusParams({required this.consentType});

  @override
  List<Object?> get props => [consentType];
}

/// Parameters for recording an acceptance.
class RecordConsentParams extends Equatable {
  /// Which consent is being accepted.
  final ConsentType consentType;

  /// The published version the user is accepting.
  ///
  /// Passed explicitly rather than resolved inside the use case so the caller
  /// records the version it actually showed the user, not whichever version
  /// happened to be published by the time the write ran.
  final int version;

  const RecordConsentParams({
    required this.consentType,
    required this.version,
  });

  @override
  List<Object?> get props => [consentType, version];
}

/// Parameters for recording a withdrawal.
///
/// No version: a withdrawal revokes whatever the user currently has on file.
class WithdrawConsentParams extends Equatable {
  /// Which consent is being withdrawn.
  final ConsentType consentType;

  const WithdrawConsentParams({required this.consentType});

  @override
  List<Object?> get props => [consentType];
}
