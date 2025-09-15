import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  late Clock clock;

  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
    clock = Modular.get<Clock>();
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeApp(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders welcome text with user full name and logs out', (
    tester,
  ) async {
    final nowIso = clock.now().toIso8601String();
    const credentialId = 'cred-1';
    const email = 'john.doe@example.com';
    const firstName = 'John';
    const lastName = 'Doe';

    fakeSupabase.setCurrentUser(
      FakeUser(id: credentialId, email: email, createdAt: nowIso),
    );

    fakeSupabase.addTableData('users', [
      {
        'id': '1',
        'credential_id': credentialId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'professional_role': 'Engineer',
        'created_at': nowIso,
        'updated_at': nowIso,
        'user_status': 'active',
        'user_preferences': <String, dynamic>{},
      },
    ]);

    await tester.pumpWidget(makeApp(const DashboardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, $firstName $lastName!'), findsOneWidget);
    expect(find.text('You are now logged in to your account'), findsOneWidget);

    await tester.tap(find.widgetWithText(CoreButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(router.navigationHistory.isNotEmpty, isTrue);
    expect(router.navigationHistory.first.route, fullLoginRoute);
  });
}
