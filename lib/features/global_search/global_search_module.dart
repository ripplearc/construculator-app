import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/data/data_source/interfaces/global_search_data_source.dart';
import 'package:construculator/features/global_search/data/data_source/remote_global_search_data_source.dart';
import 'package:construculator/features/global_search/data/repositories/global_search_repository_impl.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module for the global search feature.
///
/// Provides [GlobalSearchDataSource] and [GlobalSearchRepository] bindings
/// for dependency injection.
class GlobalSearchModule extends Module {
  final AppBootstrap appBootstrap;

  GlobalSearchModule(this.appBootstrap);

  @override
  List<Module> get imports => [SupabaseModule(appBootstrap)];

  @override
  void binds(Injector i) {
    i.addLazySingleton<GlobalSearchDataSource>(
      () => RemoteGlobalSearchDataSource(
        supabaseWrapper: appBootstrap.supabaseWrapper,
      ),
    );
    i.addLazySingleton<GlobalSearchRepository>(
      () => GlobalSearchRepositoryImpl(dataSource: i()),
    );
  }
}
