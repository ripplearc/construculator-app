import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/logging/testing/fake_logger_wrapper.dart';

void main() {
  late FakeLoggerWrapper fakeLogger;

  setUp(() {
    fakeLogger = FakeLoggerWrapper();
  });

  tearDown(() {
    fakeLogger.clear();
  });

  group('FakeLoggerWrapper', () {
    test('d logs debug messages', () {
      fakeLogger.d('debug message');
      expect(fakeLogger.dMessages.length, 1);
      expect(fakeLogger.dMessages.first['message'], 'debug message');
      expect(fakeLogger.dMessages.first['error'], null);
      expect(fakeLogger.dMessages.first['stackTrace'], null);

      final error = Exception('debug error');
      final stackTrace = StackTrace.current;
      fakeLogger.d('debug message with error', error: error, stackTrace: stackTrace);
      expect(fakeLogger.dMessages.length, 2);
      expect(fakeLogger.dMessages.last['message'], 'debug message with error');
      expect(fakeLogger.dMessages.last['error'], error);
      expect(fakeLogger.dMessages.last['stackTrace'], stackTrace);
    });

    test('i logs info messages', () {
      fakeLogger.i('info message');
      expect(fakeLogger.iMessages.length, 1);
      expect(fakeLogger.iMessages.first['message'], 'info message');
            expect(fakeLogger.iMessages.first['error'], null);
      expect(fakeLogger.iMessages.first['stackTrace'], null);

      final error = Exception('info error');
      final stackTrace = StackTrace.current;
      fakeLogger.i('info message with error', error: error, stackTrace: stackTrace);
      expect(fakeLogger.iMessages.length, 2);
      expect(fakeLogger.iMessages.last['message'], 'info message with error');
      expect(fakeLogger.iMessages.last['error'], error);
      expect(fakeLogger.iMessages.last['stackTrace'], stackTrace);
    });

    test('w logs warning messages', () {
      fakeLogger.w('warning message');
      expect(fakeLogger.wMessages.length, 1);
      expect(fakeLogger.wMessages.first['message'], 'warning message');
      expect(fakeLogger.wMessages.first['error'], null);
      expect(fakeLogger.wMessages.first['stackTrace'], null);

      final error = Exception('warning error');
      final stackTrace = StackTrace.current;
      fakeLogger.w('warning message with error', error: error, stackTrace: stackTrace);
      expect(fakeLogger.wMessages.length, 2);
      expect(fakeLogger.wMessages.last['message'], 'warning message with error');
      expect(fakeLogger.wMessages.last['error'], error);
      expect(fakeLogger.wMessages.last['stackTrace'], stackTrace);
    });

    test('e logs error messages', () {
      fakeLogger.e('error message');
      expect(fakeLogger.eMessages.length, 1);
      expect(fakeLogger.eMessages.first['message'], 'error message');
      expect(fakeLogger.eMessages.first['error'], null);
      expect(fakeLogger.eMessages.first['stackTrace'], null);

      final error = Exception('error error');
      final stackTrace = StackTrace.current;
      fakeLogger.e('error message with error', error: error, stackTrace: stackTrace);
      expect(fakeLogger.eMessages.length, 2);
      expect(fakeLogger.eMessages.last['message'], 'error message with error');
      expect(fakeLogger.eMessages.last['error'], error);
      expect(fakeLogger.eMessages.last['stackTrace'], stackTrace);
    });

    test('f logs fatal messages', () {
      fakeLogger.f('fatal message');
      expect(fakeLogger.fMessages.length, 1);
      expect(fakeLogger.fMessages.first['message'], 'fatal message');
      expect(fakeLogger.fMessages.first['error'], null);
      expect(fakeLogger.fMessages.first['stackTrace'], null);

      final error = Exception('fatal error');
      final stackTrace = StackTrace.current;
      fakeLogger.f('fatal message with error', error: error, stackTrace: stackTrace);
      expect(fakeLogger.fMessages.length, 2);
      expect(fakeLogger.fMessages.last['message'], 'fatal message with error');
      expect(fakeLogger.fMessages.last['error'], error);
      expect(fakeLogger.fMessages.last['stackTrace'], stackTrace);
    });

    test('clear removes all messages', () {
      fakeLogger.d('debug');
      fakeLogger.i('info');
      fakeLogger.w('warning');
      fakeLogger.e('error');
      fakeLogger.f('fatal');

      expect(fakeLogger.dMessages.isNotEmpty, true);
      expect(fakeLogger.iMessages.isNotEmpty, true);
      expect(fakeLogger.wMessages.isNotEmpty, true);
      expect(fakeLogger.eMessages.isNotEmpty, true);
      expect(fakeLogger.fMessages.isNotEmpty, true);

      fakeLogger.clear();

      expect(fakeLogger.dMessages.isEmpty, true);
      expect(fakeLogger.iMessages.isEmpty, true);
      expect(fakeLogger.wMessages.isEmpty, true);
      expect(fakeLogger.eMessages.isEmpty, true);
      expect(fakeLogger.fMessages.isEmpty, true);
    });
  });
} 