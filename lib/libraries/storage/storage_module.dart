import 'package:construculator/libraries/storage/file_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/storage/prefixed_preferences.dart';
import 'package:construculator/libraries/storage/shared_pref_service.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:path_provider/path_provider.dart';

class StorageModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<StorageService>(
      () => SharedPrefService(
        preferences: PrefixedPreferences(prefix: SharedPrefService.keyPrefix),
      ),
    );
    i.addLazySingleton<OwnerRecordStorageService>(
      () => FileOwnerRecordStorageService(
        directory: getApplicationSupportDirectory,
      ),
    );
  }
}
