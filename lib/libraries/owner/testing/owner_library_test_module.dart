import 'package:construculator/libraries/owner/domain/repositories/owner_repository.dart';
import 'package:construculator/libraries/owner/testing/fake_owner_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Test module binding [OwnerRepository] to [FakeOwnerRepository].
class OwnerLibraryTestModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<OwnerRepository>(
      () => FakeOwnerRepository(),
      key: 'fakeOwnerRepository',
    );
  }
}
