import 'package:construculator/libraries/url_launcher/testing/fake_url_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeUrlLauncher', () {
    late FakeUrlLauncher launcher;

    setUp(() => launcher = FakeUrlLauncher());

    test('records each URL in order and reports it opened', () async {
      final firstOpened = await launcher.openExternal('https://example.com/a');
      await launcher.openExternal('https://example.com/b');

      expect(firstOpened, isTrue);
      expect(launcher.openedUrls, [
        'https://example.com/a',
        'https://example.com/b',
      ]);
    });

    test('reports a failed launch when told to, still recording it', () async {
      launcher.shouldOpen = false;

      final opened = await launcher.openExternal('https://example.com/a');

      expect(opened, isFalse);
      expect(launcher.openedUrls, ['https://example.com/a']);
    });

    test('reset clears the record and makes launches succeed again', () async {
      launcher.shouldOpen = false;
      await launcher.openExternal('https://example.com/a');

      launcher.reset();

      expect(launcher.openedUrls, isEmpty);
      expect(await launcher.openExternal('https://example.com/b'), isTrue);
    });
  });
}
