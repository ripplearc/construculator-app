import 'package:construculator/app/shell/widgets/header_row.dart';
import 'package:construculator/app/shell/widgets/notification_icon.dart';
import 'package:construculator/app/shell/widgets/profile_avatar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpHeaderRow(
    WidgetTester tester, {
    String userName = '',
    String? avatarImageUrl,
    int unreadNotificationCount = 0,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
    VoidCallback? onProfileTap,
    VoidCallback? onProjectTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: HeaderRow(
            userName: userName,
            avatarImageUrl: avatarImageUrl,
            unreadNotificationCount: unreadNotificationCount,
            onSearchTap: onSearchTap,
            onNotificationTap: onNotificationTap,
            onProfileTap: onProfileTap,
            onProjectTap: onProjectTap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders search button', (tester) async {
    await pumpHeaderRow(tester);

    expect(find.byKey(const Key('header_row_search_button')), findsOneWidget);
  });

  testWidgets('renders notification icon', (tester) async {
    await pumpHeaderRow(tester);

    expect(find.byKey(const Key('header_row_notification_icon')), findsOneWidget);
  });

  testWidgets('renders profile avatar', (tester) async {
    await pumpHeaderRow(tester);

    expect(find.byKey(const Key('header_row_profile_avatar')), findsOneWidget);
  });

  testWidgets('invokes onSearchTap when search button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpHeaderRow(tester, onSearchTap: () => tapped = true);

    await tester.tap(find.byKey(const Key('header_row_search_button')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onProjectTap when project dropdown is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpHeaderRow(tester, onProjectTap: () => tapped = true);

    await tester.tap(find.byType(InkWell).first);
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onNotificationTap when notification icon is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpHeaderRow(tester, onNotificationTap: () => tapped = true);

    await tester.tap(find.byKey(const Key('notification_icon_button')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onProfileTap when profile avatar is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpHeaderRow(tester, onProfileTap: () => tapped = true);

    await tester.tap(find.byKey(const Key('profile_avatar_button')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('passes unreadNotificationCount to NotificationIcon', (
    tester,
  ) async {
    await pumpHeaderRow(tester, unreadNotificationCount: 3);

    final icon = tester.widget<NotificationIcon>(
      find.byKey(const Key('header_row_notification_icon')),
    );
    expect(icon.unreadCount, 3);
  });

  testWidgets('passes userName and avatarImageUrl to ProfileAvatar', (
    tester,
  ) async {
    await pumpHeaderRow(tester, userName: 'Alice', avatarImageUrl: null);

    final avatar = tester.widget<ProfileAvatar>(
      find.byKey(const Key('header_row_profile_avatar')),
    );
    expect(avatar.name, 'Alice');
    expect(avatar.imageUrl, isNull);
  });
}
