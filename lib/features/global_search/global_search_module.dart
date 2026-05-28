import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/data/data_source/interfaces/global_search_data_source.dart';
import 'package:construculator/features/global_search/data/data_source/remote_global_search_data_source.dart';
import 'package:construculator/features/global_search/data/repositories/global_search_repository_impl.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/global_search_routes.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module for the global search feature.
///
/// Provides [GlobalSearchDataSource] and [GlobalSearchRepository] bindings
/// for dependency injection, and registers the [GlobalSearchPage] route.
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
    i.add<GlobalSearchBloc>(
      () => GlobalSearchBloc(repository: i()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      globalSearchPageRoute,
      guards: [AuthGuard()],
      child: (_) => const GlobalSearchPage(),
    );
  }
}
