import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Maps low-level project data exceptions into typed project failures.
class ProjectErrorMapper {
  const ProjectErrorMapper._();

  /// Converts an exception into a typed [ProjectFailure].
  static ProjectFailure toFailure(Object error) {
    return ProjectFailure(errorType: toErrorType(error));
  }

  /// Converts an exception into a typed [ProjectErrorType].
  static ProjectErrorType toErrorType(Object error) {
    if (error is TimeoutException) {
      return ProjectErrorType.timeoutError;
    }

    if (error is SocketException) {
      return ProjectErrorType.connectionError;
    }

    if (error is FormatException || error is TypeError) {
      return ProjectErrorType.parsingError;
    }

    if (error is NotFoundException) {
      return ProjectErrorType.notFoundError;
    }

    if (error is supabase.PostgrestException) {
      final postgresErrorCode = PostgresErrorCode.fromCode(error.code);

      switch (postgresErrorCode) {
        case PostgresErrorCode.noDataFound:
          return ProjectErrorType.notFoundError;
        case PostgresErrorCode.connectionFailure:
        case PostgresErrorCode.unableToConnect:
        case PostgresErrorCode.connectionDoesNotExist:
          return ProjectErrorType.connectionError;
        case PostgresErrorCode.uniqueViolation:
          return ProjectErrorType.unexpectedDatabaseError;
        case PostgresErrorCode.unknownError:
          return _isPermissionDenied(error)
              ? ProjectErrorType.permissionDenied
              : ProjectErrorType.unexpectedDatabaseError;
      }
    }

    return ProjectErrorType.unexpectedError;
  }

  static bool _isPermissionDenied(supabase.PostgrestException error) {
    return error.code == '42501' ||
        error.code == 'PGRST301' ||
        error.message.toLowerCase().contains('permission denied');
  }
}
