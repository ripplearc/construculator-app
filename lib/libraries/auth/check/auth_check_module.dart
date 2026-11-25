// coverage:ignore-file
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/check/auth_event_service.dart';
import 'package:construculator/libraries/auth/check/interfaces/check_finished_state.dart';
import 'package:construculator/libraries/auth/check/sign_in_check.dart';
import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/powersync_synced_data_service.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/storage_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Wires the sign-in check, the queue it runs on and the service that feeds
/// both from the Supabase auth events.
///
/// [AuthEventService] is an eager singleton, so it listens from the moment the
/// module is committed at app start, before the first screen.
class AuthCheckModule extends Module {
  static const _actionTimeout = Duration(seconds: 30);

  /// Where the Sentry, analytics and session objects come from.
  final AppBootstrap appBootstrap;

  /// A module that takes its Sentry, analytics and session objects from
  /// [appBootstrap].
  AuthCheckModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    SupabaseModule(appBootstrap),
    StorageModule(),
    PowerSyncModule(appBootstrap),
  ];

  @override
  void exportedBinds(Injector i) {
    i.addSingleton<AuthEventService>(
      () => AuthEventService(
        wrapper: i<SupabaseWrapper>(),
        queue: AuthEventQueue(
          actionTimeout: _actionTimeout,
          onUnstoppedRun: () => i<CheckFinishedState>().requireRestart(),
        ),
        state: i<CheckFinishedState>(),
        signInCheck: SignInCheck(
          ownerRecords: i<OwnerRecordStorageService>(),
          deleteService: LocalDataDeleteService(
            ownerRecords: i<OwnerRecordStorageService>(),
            database: i<PowerSyncDatabaseWrapper>(),
            syncedData: PowerSyncSyncedDataService(
              manager: i<PowerSyncManager>(),
            ),
            userSpace: i<StorageService>(),
          ),
          sessionService: appBootstrap.sessionService,
          powerSync: i<PowerSyncManager>(),
          wrapper: i<SupabaseWrapper>(),
          resetIdentity: _resetIdentity,
        ),
      ),
    );
  }

  Future<void> _resetIdentity() async {
    await appBootstrap.sentryWrapper.setUser(null);
    await appBootstrap.analyticsRepository.reset();
  }
}
