import 'package:construculator/libraries/storage/file_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/shared_pref_service.dart';
import 'package:construculator/libraries/storage/storage_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _StorageTestModule extends Module {
  @override
  List<Module> get imports => [StorageModule()];
}

void main() {
  group('StorageModule', () {
    setUp(() {
      Modular.init(_StorageTestModule());
      addTearDown(Modular.destroy);
    });

    test('resolves the owner record storage to the file service', () {
      expect(
        Modular.get<OwnerRecordStorageService>(),
        isA<FileOwnerRecordStorageService>(),
      );
    });

    test('resolves the user space to the shared preferences service', () {
      expect(Modular.get<StorageService>(), isA<SharedPrefService>());
    });
  });
}
