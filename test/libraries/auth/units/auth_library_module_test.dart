import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/session/testing/fake_session_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

class _TestModule extends Module {
  final AppBootstrap bootstrap;
  _TestModule(this.bootstrap);

  @override
  List<Module> get imports => [AuthLibraryModule(bootstrap)];
}

void main() {
  late FakeSessionService sessionService;
  late FakeSupabaseWrapper supabase;

  setUp(() {
    sessionService = FakeSessionService();
    final bootstrap = FakeAppBootstrapFactory.create(
      sessionService: sessionService,
    );
    supabase = bootstrap.supabaseWrapper as FakeSupabaseWrapper;
    Modular.init(_TestModule(bootstrap));
  });

  tearDown(Modular.destroy);

  test(
    'disposing the AuthManager binding stops it reacting to auth events',
    () {
      Modular.get<AuthManager>();
      FakeUser user(String id) =>
          FakeUser(id: id, email: '$id@example.com', createdAt: '2026-11-01');

      supabase.setCurrentUser(user('first'));
      expect(sessionService.isActive, true);

      sessionService.endSession();
      Modular.dispose<AuthManager>();
      supabase.setCurrentUser(user('second'));

      expect(
        sessionService.isActive,
        false,
        reason: 'an auth event reached the manager after dispose',
      );
    },
  );
}
