import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:patrol/patrol.dart';

import 'features/auth/cuj_1_login_test.dart' as cuj1;
import 'features/auth/cuj_2_registration_test.dart' as cuj2;
import 'utils/clean_state.dart';

void main() {
  // Runs after every CUJ test registered below, clearing session and
  // PowerSync state so neither the next test in this run nor the next full
  // suite invocation inherits it. A new CUJ file needs nothing beyond
  // importing and calling its `main()` here to get this for free.
  patrolTearDown(
    () => resetE2EState(
      authManager: Modular.get<AuthManager>(),
      powerSyncManager: Modular.get<PowerSyncManager>(),
    ),
  );

  cuj1.main();
  cuj2.main();
}
