import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/project/data/project_error_mapper.dart';
import 'package:construculator/libraries/project/domain/project_error_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:stack_trace/stack_trace.dart';

void main() {
  group('ProjectErrorMapper', () {
    test('maps timeout exceptions to timeoutError', () {
      expect(
        ProjectErrorMapper.toErrorType(TimeoutException('request timed out')),
        ProjectErrorType.timeoutError,
      );
    });

    test('maps socket exceptions to connectionError', () {
      expect(
        ProjectErrorMapper.toErrorType(
          const SocketException('connection lost'),
        ),
        ProjectErrorType.connectionError,
      );
    });

    test('maps format and type errors to parsingError', () {
      expect(
        ProjectErrorMapper.toErrorType(
          const FormatException('invalid payload'),
        ),
        ProjectErrorType.parsingError,
      );

      expect(
        ProjectErrorMapper.toErrorType(TypeError()),
        ProjectErrorType.parsingError,
      );
    });

    test('maps NotFoundException to notFoundError', () {
      expect(
        ProjectErrorMapper.toErrorType(
          NotFoundException(Trace.current(), Exception('missing project')),
        ),
        ProjectErrorType.notFoundError,
      );
    });

    test('maps NetworkException to connectionError', () {
      expect(
        ProjectErrorMapper.toErrorType(
          NetworkException(Trace.current(), Exception('network down')),
        ),
        ProjectErrorType.connectionError,
      );
    });

    test('maps ServerException to unexpectedDatabaseError', () {
      expect(
        ProjectErrorMapper.toErrorType(
          ServerException(Trace.current(), Exception('server error')),
        ),
        ProjectErrorType.unexpectedDatabaseError,
      );
    });

    test('maps PostgrestException no-data responses to notFoundError', () {
      expect(
        ProjectErrorMapper.toErrorType(
          const supabase.PostgrestException(
            message: 'record not found',
            code: 'PGRST116',
          ),
        ),
        ProjectErrorType.notFoundError,
      );
    });

    test('maps permission denied responses to permissionDenied via code 42501',
        () {
      expect(
        ProjectErrorMapper.toErrorType(
          const supabase.PostgrestException(
            message: 'some db error',
            code: '42501',
          ),
        ),
        ProjectErrorType.permissionDenied,
      );
    });

    test('maps permission denied responses to permissionDenied via PGRST301',
        () {
      expect(
        ProjectErrorMapper.toErrorType(
          const supabase.PostgrestException(
            message: 'JWT expired',
            code: 'PGRST301',
          ),
        ),
        ProjectErrorType.permissionDenied,
      );
    });

    test(
        'maps permission denied responses to permissionDenied via message text',
        () {
      expect(
        ProjectErrorMapper.toErrorType(
          const supabase.PostgrestException(
            message: 'permission denied for schema public',
            code: '99999',
          ),
        ),
        ProjectErrorType.permissionDenied,
      );
    });

    test('maps unknown errors to unexpectedError', () {
      expect(
        ProjectErrorMapper.toErrorType(Exception('boom')),
        ProjectErrorType.unexpectedError,
      );
    });

    test('toFailure wraps the mapped error type', () {
      final failure = ProjectErrorMapper.toFailure(
        const supabase.PostgrestException(
          message: 'permission denied for table projects',
          code: '42501',
        ),
      );

      expect(failure.errorType, ProjectErrorType.permissionDenied);
    });
  });
}
