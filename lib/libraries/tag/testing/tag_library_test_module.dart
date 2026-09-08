import 'package:construculator/libraries/tag/domain/repositories/tag_repository.dart';
import 'package:construculator/libraries/tag/testing/fake_tag_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Test module binding [TagRepository] to [FakeTagRepository].
class TagLibraryTestModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<TagRepository>(() => FakeTagRepository());
  }
}
