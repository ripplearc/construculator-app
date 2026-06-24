import 'package:construculator/app/shell/widgets/profile_avatar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpAvatar(
    WidgetTester tester, {
    String name = 'John',
    String? imageUrl,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileAvatar(name: name, imageUrl: imageUrl, onTap: onTap),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the profile avatar button', (tester) async {
    await pumpAvatar(tester);

    expect(find.byKey(const Key('profile_avatar_button')), findsOneWidget);
  });

  testWidgets('shows letter avatar when imageUrl is null', (tester) async {
    await pumpAvatar(tester, imageUrl: null);

    expect(find.byType(CoreLetterAvatar), findsOneWidget);
  });

  testWidgets('shows letter avatar when imageUrl is empty', (tester) async {
    await pumpAvatar(tester, imageUrl: '');

    expect(find.byType(CoreLetterAvatar), findsOneWidget);
  });

  testWidgets('shows CoreAvatar without letter fallback when imageUrl is provided', (
    tester,
  ) async {
    // Suppress the image resource service error: NetworkImage returns HTTP 400
    // in the test environment. The widget structure (no CoreLetterAvatar) is
    // what matters here, not whether the image actually loads.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.library != 'image resource service') {
        originalOnError!(details);
      }
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await pumpAvatar(tester, imageUrl: 'https://example.com/avatar.jpg');

    expect(find.byType(CoreLetterAvatar), findsNothing);
    expect(find.byType(CoreAvatar), findsOneWidget);
  });

  testWidgets('invokes onTap callback when tapped', (tester) async {
    var tapped = false;
    await pumpAvatar(tester, onTap: () => tapped = true);

    await tester.tap(find.byKey(const Key('profile_avatar_button')));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
