import 'package:construculator/libraries/consent/consent_library_module.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/retrying_remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/repositories/consent_repository_impl.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/verify_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/watch_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/withdraw_consent_usecase.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

class _FakeRouteManager extends Fake implements RouteManager {}

// Mirrors the ten binds registered across this module and ConsentModule
// (which imports it) inside a single Modular tree -- not a bare Injector(),
// because two of the four dependencies in ConsentRepositoryImpl's factory
// resolve through Modular.get<SupabaseWrapper>()/<Clock>() rather than i(),
// which requires an initialized Modular tree to answer at all.
class _ConsentModuleTestHarness extends Module {
  @override
  List<Module> get imports => [
    ConsentLibraryModule(FakeAppBootstrapFactory.create()),
  ];

  @override
  void binds(Injector i) {
    i.add<RouteManager>(_FakeRouteManager.new);
  }
}

void main() {
  group('ConsentLibraryModule', () {
    setUp(() {
      Modular.init(_ConsentModuleTestHarness());
    });

    tearDown(Modular.destroy);

    // #550 B3: nothing constructed either consent module on this branch, so
    // a mis-targeted i(), a missing import, or a bind registered against the
    // wrong type would not fail until a human first navigated to the gate
    // route. This is the resolution proof that closes it.
    test('every consent bind resolves', () {
      final repository = Modular.get<ConsentRepository>();
      final remoteDataSource = Modular.get<RemoteConsentDataSource>();

      expect(repository, isA<ConsentRepositoryImpl>());
      expect(remoteDataSource, isA<RetryingRemoteConsentDataSource>());
      expect(Modular.get<CheckConsentStatusUseCase>(), isNotNull);
      expect(Modular.get<WatchConsentStatusUseCase>(), isNotNull);
      expect(Modular.get<VerifyConsentStatusUseCase>(), isNotNull);
      expect(Modular.get<RecordConsentUseCase>(), isNotNull);
      expect(Modular.get<WithdrawConsentUseCase>(), isNotNull);

      repository.dispose();
    });

    test('the repository bind is a singleton', () {
      // addLazySingleton, not add -- the route guard, the gate feature and
      // signup all resolve this independently and must share one instance,
      // or a write from one would be invisible to a read from another.
      final first = Modular.get<ConsentRepository>();
      final second = Modular.get<ConsentRepository>();

      expect(identical(first, second), isTrue);

      first.dispose();
    });
  });
}
