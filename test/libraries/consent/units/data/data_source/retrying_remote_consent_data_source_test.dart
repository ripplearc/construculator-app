import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/consent/data/data_source/retrying_remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_remote_consent_data_source.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

ConsentVersionDto _version(int number) => ConsentVersionDto(
  id: 'version-$number',
  consentType: ConsentType.termsAndPrivacy,
  version: number,
  documentUrl: 'https://ripplearc.com/legal/terms-and-privacy',
  publishedAt: DateTime.fromMillisecondsSinceEpoch(0),
);

/// Backoff with no real delay. The production defaults are exercised
/// separately, in the test that pins their actual durations.
const _noDelay = [Duration.zero, Duration.zero, Duration.zero];

void main() {
  group('RetryingRemoteConsentDataSource', () {
    late FakeRemoteConsentDataSource inner;
    late RetryingRemoteConsentDataSource dataSource;

    setUp(() {
      inner = FakeRemoteConsentDataSource();
      dataSource = RetryingRemoteConsentDataSource(inner, backoff: _noDelay);
    });

    test(
      'returns the inner result without retrying when it succeeds',
      () async {
        inner.publishedVersionsToReturn = [_version(1)];

        final result = await dataSource.fetchPublishedVersions();

        expect(result, hasLength(1));
        expect(inner.callCount, 1);
      },
    );

    test('retries a transient failure and succeeds', () async {
      inner
        ..error = const SocketException('offline')
        ..failuresBeforeSuccess = 2
        ..publishedVersionsToReturn = [_version(1)];

      final result = await dataSource.fetchPublishedVersions();

      expect(result.single.version, 1);
      expect(inner.callCount, 3, reason: 'two failures then a success');
    });

    test('gives up after three retries and rethrows', () async {
      inner.error = const SocketException('offline');

      await expectLater(
        () => dataSource.fetchPublishedVersions(),
        throwsA(isA<SocketException>()),
      );
      expect(inner.callCount, 4, reason: 'one attempt plus three retries');
    });

    test('retries a timeout', () async {
      inner
        ..error = TimeoutException('slow')
        ..failuresBeforeSuccess = 1
        ..publishedVersionsToReturn = [_version(2)];

      await dataSource.fetchPublishedVersions();

      expect(inner.callCount, 2);
    });

    // A connection dropped mid-flight surfaces as http.ClientException, not
    // the dart:io HttpException the transport never actually throws.
    test('retries an http.ClientException from a dropped connection', () async {
      inner
        ..error = http.ClientException(
          'Connection closed before full header was received',
        )
        ..failuresBeforeSuccess = 1
        ..publishedVersionsToReturn = [_version(4)];

      await dataSource.fetchPublishedVersions();

      expect(inner.callCount, 2);
    });

    // A parse failure or a permission denial fails identically every time, so
    // retrying only delays the answer the gate is waiting on.
    test('does not retry a non-transient failure', () async {
      inner.error = const FormatException('bad payload');

      await expectLater(
        () => dataSource.fetchPublishedVersions(),
        throwsA(isA<FormatException>()),
      );
      expect(inner.callCount, 1);
    });

    // A connection-level failure can surface through PostgREST rather than
    // as a raw socket error, and it deserves the same backoff.
    test('retries a PostgrestException carrying a connection code', () async {
      inner
        ..error = PostgrestException(message: 'cannot connect', code: '08006')
        ..failuresBeforeSuccess = 1
        ..publishedVersionsToReturn = [_version(3)];

      await dataSource.fetchPublishedVersions();

      expect(inner.callCount, 2);
    });

    test(
      'does not retry a PostgrestException with a non-connection code',
      () async {
        inner.error = PostgrestException(
          message: 'not found',
          code: 'PGRST116',
        );

        await expectLater(
          () => dataSource.fetchPublishedVersions(),
          throwsA(isA<PostgrestException>()),
        );
        expect(inner.callCount, 1);
      },
    );

    test('stops retrying when a later failure is not transient', () async {
      inner.errorSequence.addAll([
        const SocketException('offline'),
        const FormatException('bad payload'),
      ]);

      await expectLater(
        () => dataSource.fetchPublishedVersions(),
        throwsA(isA<FormatException>()),
      );
      expect(
        inner.callCount,
        2,
        reason:
            'abandons the remaining budget once a failure is not '
            'transient, rather than carrying on',
      );
    });

    // Virtual time again: a stalled attempt racing its own timeout is a
    // timing assertion, and racing two real durations is the one shape in
    // this file that could flake on a loaded machine.
    test('retries an attempt that exceeds attemptTimeout', () {
      fakeAsync((async) {
        dataSource = RetryingRemoteConsentDataSource(
          inner,
          backoff: _noDelay,
          attemptTimeout: const Duration(seconds: 1),
        );
        inner
          ..delaySequence.add(const Duration(seconds: 5))
          ..publishedVersionsToReturn = [_version(5)];

        final result = <ConsentVersionDto>[];
        dataSource.fetchPublishedVersions().then(result.addAll);

        async.elapse(const Duration(milliseconds: 999));
        expect(inner.callCount, 1, reason: 'first attempt still stalled');

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(inner.callCount, 2, reason: 'stalled first attempt, fast retry');
        expect(result.single.version, 5);
      });
    });
  });

  // Drives virtual time via fake_async so the assertion on the declared
  // delays costs milliseconds, not the 3.25s those delays actually total.
  test('waits the delays _backoff declares between retries', () {
    fakeAsync((async) {
      final inner = FakeRemoteConsentDataSource()
        ..error = const SocketException('offline')
        ..failuresBeforeSuccess = 2
        ..publishedVersionsToReturn = [_version(1)];
      final dataSource = RetryingRemoteConsentDataSource(inner);

      var completed = false;
      dataSource.fetchPublishedVersions().then((_) => completed = true);

      async.flushMicrotasks();
      expect(inner.callCount, 1, reason: 'first attempt runs immediately');

      async.elapse(const Duration(milliseconds: 249));
      expect(inner.callCount, 1, reason: 'not yet at the 250ms mark');

      async.elapse(const Duration(milliseconds: 1));
      expect(inner.callCount, 2, reason: 'retry fires at exactly 250ms');

      async.elapse(const Duration(milliseconds: 999));
      expect(inner.callCount, 2, reason: 'not yet at the 1s mark');

      async.elapse(const Duration(milliseconds: 1));
      expect(inner.callCount, 3, reason: 'retry fires at exactly 1s later');
      expect(completed, isTrue);
    });
  });
}
