import 'package:construculator/libraries/analytics/domain/utils/failure_analytics_reason.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FailureAnalyticsReason', () {
    test('returns the AuthErrorType name for an AuthFailure', () {
      const failure = AuthFailure(errorType: AuthErrorType.invalidCredentials);

      expect(failure.analyticsReason, 'invalidCredentials');
    });

    test('falls back to "unexpected" for a non-AuthFailure', () {
      final failure = UnexpectedFailure();

      expect(failure.analyticsReason, 'unexpected');
    });
  });
}
