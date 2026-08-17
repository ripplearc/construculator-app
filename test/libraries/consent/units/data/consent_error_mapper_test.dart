import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/consent/data/consent_error_mapper.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:stack_trace/stack_trace.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('ConsentErrorMapper', () {
    test('maps timeout exceptions to timeoutError', () {
      expect(
        ConsentErrorMapper.toErrorType(TimeoutException('write timed out')),
        ConsentErrorType.timeoutError,
      );
    });

    test('maps socket exceptions to connectionError', () {
      expect(
        ConsentErrorMapper.toErrorType(const SocketException('no route')),
        ConsentErrorType.connectionError,
      );
    });

    test('maps a dropped connection to connectionError', () {
      // http.ClientException, not HttpException: IOClient converts dart:io's
      // HttpException into a plain ClientException before it ever escapes the
      // HTTP layer, so this is the type a mid-flight drop actually arrives as.
      expect(
        ConsentErrorMapper.toErrorType(
          http.ClientException(
            'Connection closed before full header was received',
          ),
        ),
        ConsentErrorType.connectionError,
      );
    });

    test('maps NetworkException to connectionError', () {
      expect(
        ConsentErrorMapper.toErrorType(
          NetworkException(Trace.current(), Exception('network down')),
        ),
        ConsentErrorType.connectionError,
      );
    });

    test('maps format and type errors to parsingError', () {
      expect(
        ConsentErrorMapper.toErrorType(const FormatException('bad payload')),
        ConsentErrorType.parsingError,
      );

      expect(
        ConsentErrorMapper.toErrorType(TypeError()),
        ConsentErrorType.parsingError,
      );
    });

    test('maps ServerException to unexpectedDatabaseError', () {
      expect(
        ConsentErrorMapper.toErrorType(
          ServerException(Trace.current(), Exception('server error')),
        ),
        ConsentErrorType.unexpectedDatabaseError,
      );
    });

    test('maps auth exceptions to authenticationError', () {
      // The session expired between the guard's check and the write, so there
      // is no user to attribute the record to.
      expect(
        ConsentErrorMapper.toErrorType(
          const supabase.AuthException('invalid claim: missing sub'),
        ),
        ConsentErrorType.authenticationError,
      );
    });

    test('maps RLS rejections to permissionDenied', () {
      // The case the value exists for: the insert policy on user_consents
      // refused the row.
      expect(
        ConsentErrorMapper.toErrorType(
          const supabase.PostgrestException(
            message: 'new row violates row-level security policy',
            code: '42501',
          ),
        ),
        ConsentErrorType.permissionDenied,
      );
    });

    test('maps an expired token to permissionDenied via PGRST301', () {
      expect(
        ConsentErrorMapper.toErrorType(
          const supabase.PostgrestException(
            message: 'JWT expired',
            code: 'PGRST301',
          ),
        ),
        ConsentErrorType.permissionDenied,
      );
    });

    test('maps a prose permission denial to permissionDenied', () {
      expect(
        ConsentErrorMapper.toErrorType(
          const supabase.PostgrestException(
            message: 'permission denied for table user_consents',
            code: '99999',
          ),
        ),
        ConsentErrorType.permissionDenied,
      );
    });

    test('maps postgrest connection codes to connectionError', () {
      for (final code in ['08000', '08006', '08001', '08003']) {
        expect(
          ConsentErrorMapper.toErrorType(
            supabase.PostgrestException(message: 'connection lost', code: code),
          ),
          ConsentErrorType.connectionError,
          reason: 'code $code should map to connectionError',
        );
      }
    });

    test('maps remaining postgrest codes to unexpectedDatabaseError', () {
      for (final code in ['23505', 'PGRST116']) {
        expect(
          ConsentErrorMapper.toErrorType(
            supabase.PostgrestException(message: 'query failed', code: code),
          ),
          ConsentErrorType.unexpectedDatabaseError,
          reason: 'code $code should map to unexpectedDatabaseError',
        );
      }
    });

    test(
      'maps an unrecognised postgrest failure to unexpectedDatabaseError',
      () {
        expect(
          ConsentErrorMapper.toErrorType(
            const supabase.PostgrestException(
              message: 'something went wrong',
              code: '99999',
            ),
          ),
          ConsentErrorType.unexpectedDatabaseError,
        );
      },
    );

    test('maps anything unrecognised to unexpectedError', () {
      // Nothing about this came from the store, so it must not be reported as
      // a database failure.
      expect(
        ConsentErrorMapper.toErrorType(StateError('bad state')),
        ConsentErrorType.unexpectedError,
      );
    });

    test('toFailure wraps the mapped error type', () {
      final failure = ConsentErrorMapper.toFailure(
        const supabase.PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      );

      expect(failure.errorType, ConsentErrorType.permissionDenied);
    });

    test('isTransient accepts conditions that can plausibly clear', () {
      expect(
        ConsentErrorMapper.isTransient(TimeoutException('write timed out')),
        isTrue,
      );
      expect(
        ConsentErrorMapper.isTransient(const SocketException('no route')),
        isTrue,
      );
      expect(
        ConsentErrorMapper.isTransient(
          http.ClientException('Connection closed'),
        ),
        isTrue,
      );
      expect(
        ConsentErrorMapper.isTransient(
          const supabase.PostgrestException(
            message: 'connection lost',
            code: '08006',
          ),
        ),
        isTrue,
      );
    });

    test('isTransient rejects failures that will not clear on retry', () {
      expect(
        ConsentErrorMapper.isTransient(const FormatException('bad payload')),
        isFalse,
      );
      expect(
        ConsentErrorMapper.isTransient(
          const supabase.PostgrestException(
            message: 'query failed',
            code: 'PGRST116',
          ),
        ),
        isFalse,
      );
      expect(
        ConsentErrorMapper.isTransient(
          const supabase.PostgrestException(
            message: 'new row violates row-level security policy',
            code: '42501',
          ),
        ),
        isFalse,
      );
    });
  });
}
