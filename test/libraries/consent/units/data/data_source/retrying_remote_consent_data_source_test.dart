import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/consent/data/data_source/retrying_remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_data_sources.dart';
import 'package:flutter_test/flutter_test.dart';

ConsentVersionDto _version(int number) => ConsentVersionDto(
  id: 'version-$number',
  consentType: ConsentType.termsAndPrivacy,
  version: number,
  documentUrl: 'https://ripplearc.com/legal/terms-and-privacy',
  publishedAt: DateTime.fromMillisecondsSinceEpoch(0),
);

void main() {
  group('RetryingRemoteConsentDataSource', () {
    late FakeRemoteConsentDataSource inner;
    late RetryingRemoteConsentDataSource dataSource;

    setUp(() {
      inner = FakeRemoteConsentDataSource();
      dataSource = RetryingRemoteConsentDataSource(inner);
    });

    test('returns the inner result without retrying when it succeeds', () async {
      inner.publishedVersions = [_version(1)];

      final result = await dataSource.fetchPublishedVersions();

      expect(result, hasLength(1));
      expect(inner.callCount, 1);
    });

    test('retries a transient failure and succeeds', () async {
      inner
        ..error = const SocketException('offline')
        ..failuresBeforeSuccess = 2
        ..publishedVersions = [_version(1)];

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
        ..publishedVersions = [_version(2)];

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
  });
}
