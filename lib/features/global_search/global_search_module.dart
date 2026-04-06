import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/data/data_source/interfaces/global_search_data_source.dart';
import 'package:construculator/features/global_search/data/data_source/remote_global_search_data_source.dart';
import 'package:construculator/features/global_search/data/repositories/global_search_repository_impl.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/features/global_search/domain/usecases/delete_recent_search_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/get_recent_searches_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/get_search_suggestions_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/perform_search_use_case.dart';
import 'package:construculator/features/global_search/domain/usecases/save_recent_search_use_case.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module for the global search feature.
///
/// Provides [GlobalSearchDataSource], [GlobalSearchRepository], domain use
/// cases, and [GlobalSearchBloc] bindings for dependency injection.
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
    i.addLazySingleton<PerformSearchUseCase>(() => PerformSearchUseCase(i()));
    i.addLazySingleton<GetRecentSearchesUseCase>(
      () => GetRecentSearchesUseCase(i()),
    );
    i.addLazySingleton<SaveRecentSearchUseCase>(
      () => SaveRecentSearchUseCase(i()),
    );
    i.addLazySingleton<DeleteRecentSearchUseCase>(
      () => DeleteRecentSearchUseCase(i()),
    );
    i.addLazySingleton<GetSearchSuggestionsUseCase>(
      () => GetSearchSuggestionsUseCase(i()),
    );
    i.add<GlobalSearchBloc>(
      () => GlobalSearchBloc(
        performSearchUseCase: i(),
        getRecentSearchesUseCase: i(),
        saveRecentSearchUseCase: i(),
        deleteRecentSearchUseCase: i(),
        getSearchSuggestionsUseCase: i(),
      ),
    );
  }
}
