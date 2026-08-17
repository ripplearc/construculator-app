import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Maps low-level consent write exceptions into typed consent failures.
///
/// Lives in the data layer rather than beside the enum because classifying a
/// failure means recognizing `PostgrestException` codes and auth errors, and
/// the domain is not allowed to know those types exist.
class ConsentErrorMapper {
  const ConsentErrorMapper._();

  /// Converts an exception into a typed [ConsentFailure].
  static ConsentFailure toFailure(Object error) {
    return ConsentFailure(errorType: toErrorType(error));
  }

  /// Whether [error] can plausibly clear on another attempt.
  ///
  /// Derived from [toErrorType] rather than listed separately, so the retry
  /// decorator and the failure taxonomy cannot classify the same exception
  /// two different ways.
  static bool isTransient(Object error) {
    final errorType = toErrorType(error);
    return errorType == ConsentErrorType.connectionError ||
        errorType == ConsentErrorType.timeoutError;
  }

  /// Converts an exception into a typed [ConsentErrorType].
  static ConsentErrorType toErrorType(Object error) {
    if (error is TimeoutException) {
      return ConsentErrorType.timeoutError;
    }

    // http.ClientException, not HttpException: IOClient converts dart:io's
    // HttpException into a plain ClientException before it ever escapes the
    // HTTP layer, so the mid-flight-drop case ("Connection closed before
    // full header was received") only matches this type. SocketException
    // still matches directly — IOClient's _ClientSocketException implements
    // it.
    if (error is SocketException || error is http.ClientException) {
      return ConsentErrorType.connectionError;
    }

    if (error is NetworkException) {
      return ConsentErrorType.connectionError;
    }

    if (error is FormatException || error is TypeError) {
      return ConsentErrorType.parsingError;
    }

    if (error is ServerException) {
      return ConsentErrorType.unexpectedDatabaseError;
    }

    if (error is supabase.AuthException) {
      return ConsentErrorType.authenticationError;
    }

    if (error is supabase.PostgrestException) {
      // sqlclient_unable_to_establish_sqlconnection: PostgresErrorCode has
      // no value for it, and must not gain one — the enum is switched on
      // exhaustively elsewhere in the codebase.
      if (error.code == '08000') {
        return ConsentErrorType.connectionError;
      }

      final postgresErrorCode = PostgresErrorCode.fromCode(error.code);

      switch (postgresErrorCode) {
        case PostgresErrorCode.rlsViolation:
          return ConsentErrorType.permissionDenied;
        case PostgresErrorCode.connectionFailure:
        case PostgresErrorCode.unableToConnect:
        case PostgresErrorCode.connectionDoesNotExist:
          return ConsentErrorType.connectionError;
        case PostgresErrorCode.uniqueViolation:
        case PostgresErrorCode.noDataFound:
          return ConsentErrorType.unexpectedDatabaseError;
        case PostgresErrorCode.unknownError:
          return _isPermissionDenied(error)
              ? ConsentErrorType.permissionDenied
              : ConsentErrorType.unexpectedDatabaseError;
      }
    }

    return ConsentErrorType.unexpectedError;
  }

  /// Recognises the rejections [PostgresErrorCode] has no value for.
  ///
  /// An expired or missing JWT arrives as `PGRST301`, and PostgREST reports
  /// some policy denials in prose rather than a code.
  static bool _isPermissionDenied(supabase.PostgrestException error) {
    return error.code == 'PGRST301' ||
        error.message.toLowerCase().contains('permission denied');
  }
}
