import 'package:construculator/libraries/consent/data/consent_audit_metadata_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentAuditMetadataImpl', () {
    late ConsentAuditMetadataImpl metadata;

    setUp(() {
      metadata = ConsentAuditMetadataImpl(appVersion: '2.3.1');
    });

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('reports the app version it was built with', () {
      expect(metadata.appVersion, '2.3.1');
    });

    // The names AnalyticsRepositoryImpl sends as `platform`, so a consent row
    // and an analytics event name the same device the same way. Its test
    // pins the same six names.
    const analyticsPlatformNames = {
      TargetPlatform.iOS: 'ios',
      TargetPlatform.android: 'android',
      TargetPlatform.macOS: 'macos',
      TargetPlatform.windows: 'windows',
      TargetPlatform.linux: 'linux',
      TargetPlatform.fuchsia: 'fuchsia',
    };

    test('reports every platform by the name analytics uses', () {
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          metadata.platform,
          analyticsPlatformNames[platform],
          reason: '$platform',
        );
      }
    });
  });
}
