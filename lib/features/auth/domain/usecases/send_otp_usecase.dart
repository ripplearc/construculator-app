// coverage:ignore-file
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// This is the use case for sending an OTP to the specified address.
class SendOtpUseCase {
  final AuthManager authManager;

  SendOtpUseCase(this.authManager);

  /// Sends an OTP to the specified address using the auth manager.
  /// Accepts an address and an [OtpReceiver] as parameters.
  ///
  /// Returns a [Future] that emits an [Either] containing a [Failure] or an [void].
  Future<Either<Failure, void>> call(
    String address,
    OtpReceiver receiver,
  ) async {
    final result = await authManager.sendOtp(address, receiver);
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
