import 'dart:io';

import 'package:construculator/libraries/storage/database_file_path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('resolveDatabaseFilePath', () {
    test('puts the database file in the folder it is given', () async {
      final directory = Directory(p.join('app', 'support'));

      final path = await resolveDatabaseFilePath(
        directory: () async => directory,
      );

      expect(path, p.join('app', 'support', 'construculator.db'));
    });

    test('rethrows when the folder cannot be resolved', () async {
      await expectLater(
        resolveDatabaseFilePath(
          directory: () async => throw StateError('no folder'),
        ),
        throwsStateError,
      );
    });
  });
}
