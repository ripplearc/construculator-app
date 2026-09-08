import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/owner/data/data_source/interfaces/owner_data_source.dart';
import 'package:construculator/libraries/owner/data/data_source/remote_owner_data_source.dart';
import 'package:construculator/libraries/owner/data/repositories/owner_repository_impl.dart';
import 'package:construculator/libraries/owner/domain/repositories/owner_repository.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module providing project-owner fetching dependencies
/// ([OwnerDataSource], [OwnerRepository]).
class OwnerLibraryModule extends Module {
  /// Bootstrap used to resolve the Supabase dependencies.
  final AppBootstrap appBootstrap;

  /// Creates an [OwnerLibraryModule].
  OwnerLibraryModule(this.appBootstrap);

  @override
  List<Module> get imports => [SupabaseModule(appBootstrap)];

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<OwnerDataSource>(
      () => RemoteOwnerDataSource(supabaseWrapper: i.get()),
    );

    i.addLazySingleton<OwnerRepository>(
      () => OwnerRepositoryImpl(dataSource: i.get()),
    );
  }
}
