import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:construculator/libraries/tag/data/data_source/interfaces/tag_data_source.dart';
import 'package:construculator/libraries/tag/data/data_source/remote_tag_data_source.dart';
import 'package:construculator/libraries/tag/data/repositories/tag_repository_impl.dart';
import 'package:construculator/libraries/tag/domain/repositories/tag_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module providing tag fetching dependencies ([TagDataSource], [TagRepository]).
class TagLibraryModule extends Module {
  /// Bootstrap used to resolve the Supabase dependencies.
  final AppBootstrap appBootstrap;

  /// Creates a [TagLibraryModule].
  TagLibraryModule(this.appBootstrap);

  @override
  List<Module> get imports => [SupabaseModule(appBootstrap)];

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<TagDataSource>(
      () => RemoteTagDataSource(supabaseWrapper: i.get()),
    );

    i.addLazySingleton<TagRepository>(
      () => TagRepositoryImpl(dataSource: i.get()),
    );
  }
}
