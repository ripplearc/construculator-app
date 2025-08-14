import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// This is the use case for verifying an OTP.
class VerifyOtpUseCase {
  final AuthManager authManager;

  VerifyOtpUseCase(this.authManager);

  /// Verifies an OTP using the auth manager.
  /// Accepts an email, an OTP, and an [OtpReceiver] as parameters.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or an [void].
  Future<Either<Failure, void>> call(String email, String otp, OtpReceiver receiver) async {
    final result = await authManager.verifyOtp(email, otp, receiver);
    if (!result.isSuccess) {
      final errorType = result.errorType;
      if (errorType == null) {
        return Left(UnexpectedFailure());
      }
      return Left(AuthFailure(errorType: errorType));
    }
    return Right(null);
  }
}