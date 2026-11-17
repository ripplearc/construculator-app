import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/company/data/current_company_resolver_impl.dart';
import 'package:construculator/libraries/company/data/data_source/interfaces/local_current_company_data_source.dart';
import 'package:construculator/libraries/company/data/data_source/powersync_local_current_company_data_source.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module providing the data the company id is kept in on the device.
///
/// [CurrentCompanyResolver] itself is added by [registerCompanyPerUserObjects]
/// when a user signs in.
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
  }
}

/// Adds the company objects that belong to one signed-in user: the resolver,
/// which caches the company id.
///
/// Only the session module calls this, so the next user starts with an empty
/// cache. The id kept on the device is not part of the session, and
/// [CurrentCompanyResolver.clearCache] still clears it.
void registerCompanyPerUserObjects(Injector i) => _registerPerUserObjects(i);

void _registerPerUserObjects(Injector i) {
  i.addLazySingleton<CurrentCompanyResolver>(
    () => CurrentCompanyResolverImpl(
      supabaseWrapper: Modular.get<SupabaseWrapper>(),
      localDataSource: Modular.get<LocalCurrentCompanyDataSource>(),
    ),
  );
}
