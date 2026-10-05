import 'package:construculator/libraries/url_launcher/url_launcher_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlLauncherImpl', () {
    late List<Uri> launchedUris;

    UrlLauncherImpl launcherThatOpens({required bool opens}) => UrlLauncherImpl(
      launch: (uri) async {
        launchedUris.add(uri);
        return opens;
      },
    );

    setUp(() => launchedUris = []);

    test('hands the parsed URL to the platform and reports it opened', () async {
      final launcher = launcherThatOpens(opens: true);

      final opened = await launcher.openExternal('https://example.com/terms');

      expect(opened, isTrue);
      expect(launchedUris, [Uri.parse('https://example.com/terms')]);
    });

    test('reports false when no app can open the URL', () async {
      final launcher = launcherThatOpens(opens: false);

      final opened = await launcher.openExternal('https://example.com/terms');

      expect(opened, isFalse);
    });

    test('reports false instead of throwing when the platform fails', () async {
      final launcher = UrlLauncherImpl(
        launch: (_) async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'),
      );

      final opened = await launcher.openExternal('https://example.com/terms');

      expect(opened, isFalse);
    });

    test('rejects a relative URL without reaching the platform', () async {
      final launcher = launcherThatOpens(opens: true);

      final opened = await launcher.openExternal('legal/terms');

      expect(opened, isFalse);
      expect(launchedUris, isEmpty);
    });

    test('rejects a non-web URL without reaching the platform', () async {
      final launcher = launcherThatOpens(opens: true);

      final opened = await launcher.openExternal('file:///etc/hosts');

      expect(opened, isFalse);
      expect(launchedUris, isEmpty);
    });

    test('rejects an unparsable URL without reaching the platform', () async {
      final launcher = launcherThatOpens(opens: true);

      final opened = await launcher.openExternal('https://[::1');

      expect(opened, isFalse);
      expect(launchedUris, isEmpty);
    });
  });
}
