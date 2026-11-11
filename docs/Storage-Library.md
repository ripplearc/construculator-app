# Storage library

The storage library (`lib/libraries/storage/`) is the one place where the app keeps preferences, small files and the database path. A feature that stores data on the phone goes through it, so that sign-out can find and delete that data.

## Two spaces

- **User space** (`StorageService`). The default. It holds data that belongs to the signed-in user. The delete routine empties the whole space when the user changes or logs out. Keys are stored under the prefix `user.`.
- **Device space** (`DeviceSpaceStorageService`). It holds settings of the phone that carry no user data, such as "onboarding seen". Nothing deletes it on sign-out. It accepts only the values of the `DeviceSetting` enum, so a reviewer checks every new entry. Anything tied to an account belongs in the user space. Keys are stored under the prefix `device.`.

The owner record is a third, reserved part. It is one file that the user space never touches (see `OwnerRecordStorageService`).

## Using it from a feature

The library knows no feature. It offers `getData`, `saveData` and `removeData`, and the value is a string, int, double, bool or list of strings. A feature keeps its keys in one named group of its own, for example `last_used_unit.<account id>.<category>`. A method that names a feature, such as `saveCalculatorTape()`, is rejected in review.

## The database file

`resolveDatabaseFilePath()` gives the path of the PowerSync database file. Open the database through it, not through `path_provider`.

## The lint rule

`forbid_direct_storage_access` (package `ripplearc_linter`) fails the build when code imports `shared_preferences`, `path_provider` or `flutter_secure_storage` outside `lib/libraries/storage/`, `test/libraries/storage/` and the exact files listed under `forbid_direct_storage_access: allowed_files` in `analysis_options.yaml`. The listed files are the secure session storage and the stale secure storage check, which keep their own flags on purpose. Do not add a file to the list without a reason that a reviewer accepts.
