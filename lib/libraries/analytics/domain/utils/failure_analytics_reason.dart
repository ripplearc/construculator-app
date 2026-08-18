import 'package:construculator/libraries/errors/failures.dart';

/// Maps a [Failure] to a typed, PII-free reason string for analytics
/// failure events.
extension FailureAnalyticsReason on Failure {
  /// The reason to attach to an analytics failure event's `reason` property.
  String get analyticsReason =>
      this is AuthFailure ? (this as AuthFailure).errorType.name : 'unexpected';
}
