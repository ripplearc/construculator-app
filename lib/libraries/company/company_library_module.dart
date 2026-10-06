import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/company/data/current_company_resolver_impl.dart';
import 'package:construculator/libraries/company/data/data_source/interfaces/local_current_company_data_source.dart';
import 'package:construculator/libraries/company/data/data_source/powersync_local_current_company_data_source.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module providing [CurrentCompanyResolver].
///
/// Bound as a lazy singleton so its in-memory cache lives for the app
/// session rather than being recreated per call site.
class CompanyLibraryModule extends Module {
  /// Bootstrap used to resolve the Supabase dependencies.
  final AppBootstrap appBootstrap;

  /// Creates a [CompanyLibraryModule].
  CompanyLibraryModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    SupabaseModule(appBootstrap),
    PowerSyncModule(appBootstrap),
  ];

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<LocalCurrentCompanyDataSource>(
      () => PowerSyncLocalCurrentCompanyDataSource(database: i.get()),
    );
    i.addLazySingleton<CurrentCompanyResolver>(
      () => CurrentCompanyResolverImpl(
        supabaseWrapper: i.get(),
        localDataSource: i.get(),
      ),
    );
  }
}
