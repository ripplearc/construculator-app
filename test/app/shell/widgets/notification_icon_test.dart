import 'package:construculator/app/shell/widgets/notification_icon.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpIcon(
    WidgetTester tester, {
    int unreadCount = 0,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotificationIcon(unreadCount: unreadCount, onTap: onTap),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the notification icon button', (tester) async {
    await pumpIcon(tester);

    expect(find.byKey(const Key('notification_icon_button')), findsOneWidget);
  });

  testWidgets('hides badge when unreadCount is zero', (tester) async {
    await pumpIcon(tester);

    expect(find.byKey(const Key('notification_badge')), findsNothing);
  });

  testWidgets('shows badge when unreadCount is greater than zero', (
    tester,
  ) async {
    await pumpIcon(tester, unreadCount: 5);

    expect(find.byKey(const Key('notification_badge')), findsOneWidget);
  });

  testWidgets('invokes onTap callback when tapped', (tester) async {
    var tapped = false;
    await pumpIcon(tester, onTap: () => tapped = true);

    await tester.tap(find.byKey(const Key('notification_icon_button')));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
