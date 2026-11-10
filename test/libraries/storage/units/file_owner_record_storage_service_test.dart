import 'dart:io';

import 'package:construculator/libraries/storage/file_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

FileOwnerRecordStorageService buildService(Directory Function() directory) =>
    // ignore: no_direct_instantiation, reason: the service under test takes the folder as its only seam
    FileOwnerRecordStorageService(directory: () async => directory());

void main() {
  group('FileOwnerRecordStorageService', () {
    late Directory directory;
    late FileOwnerRecordStorageService service;

    File fileNamed(String name) => File(p.join(directory.path, name));

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('owner_record_test');
      service = buildService(() => directory);
    });

    tearDown(() => directory.delete(recursive: true));

    final userOne = OwnerRecord(userId: 'user-1');
    final userTwoWithFlag = OwnerRecord(
      userId: 'user-2',
      pendingDelete: const PendingDelete.arrivalOf('user-3'),
      signOutDate: DateTime.utc(2026, 11, 10),
    );

    test('reads as absent from a folder that does not exist yet', () async {
      service = buildService(
        () => Directory(p.join(directory.path, 'not', 'created')),
      );

      expect(await service.read(), isA<OwnerRecordAbsent>());
    });

    test('reads nothing from an empty folder as absent', () async {
      expect(await service.read(), isA<OwnerRecordAbsent>());
    });

    test('reads back what was written', () async {
      await service.write(userTwoWithFlag);

      final read = await service.read() as OwnerRecordFound;
      expect(read.record, userTwoWithFlag);
    });

    test(
      'two overlapping writes leave one whole record and both finish',
      () async {
        final longId = 'u' * 400;
        final first = OwnerRecord(userId: 'a$longId');
        final second = OwnerRecord(userId: 'b$longId');

        await Future.wait([service.write(first), service.write(second)]);

        final read = await service.read() as OwnerRecordFound;
        expect(read.record, second);
        expect(fileNamed('owner_record.json.tmp').existsSync(), isFalse);
      },
    );

    test('a write and a removal started together finish in order', () async {
      await Future.wait([service.write(userOne), service.remove()]);

      expect(await service.read(), isA<OwnerRecordAbsent>());
    });

    test('a failed write throws and the next write still works', () async {
      final blocker = fileNamed('blocked')..writeAsStringSync('a file');
      var target = Directory(p.join(blocker.path, 'inside'));
      service = buildService(() => target);

      await expectLater(service.write(userOne), throwsA(isA<IOException>()));

      target = directory;
      await service.write(userTwoWithFlag);
      final read = await service.read() as OwnerRecordFound;
      expect(read.record, userTwoWithFlag);
    });

    test('creates a folder that does not exist yet', () async {
      final missing = Directory(p.join(directory.path, 'a', 'b'));
      service = buildService(() => missing);

      await service.write(userOne);

      expect(await service.read(), isA<OwnerRecordFound>());
    });

    test('a second write replaces the first', () async {
      await service.write(userOne);
      await service.write(userTwoWithFlag);

      final read = await service.read() as OwnerRecordFound;
      expect(read.record, userTwoWithFlag);
    });

    test('leaves no temporary file after a write', () async {
      await service.write(userOne);

      expect(fileNamed('owner_record.json.tmp').existsSync(), isFalse);
      expect(fileNamed('owner_record.json').existsSync(), isTrue);
    });

    test('a crash before the rename leaves the old record readable', () async {
      await service.write(userOne);
      fileNamed('owner_record.json.tmp').writeAsStringSync('{"userId":"half');

      final read = await service.read() as OwnerRecordFound;
      expect(read.record, userOne);
    });

    test(
      'a write after a crash replaces the leftover temporary file',
      () async {
        fileNamed('owner_record.json.tmp').writeAsStringSync('{"userId":"half');

        await service.write(userTwoWithFlag);

        final read = await service.read() as OwnerRecordFound;
        expect(read.record, userTwoWithFlag);
      },
    );

    group('reads as unknown, never as absent, when the file is', () {
      final corruptContents = <String, String>{
        'empty': '',
        'cut off': '{"userId":"user-1',
        'not an object': '[1, 2]',
        'an object that is not a record': '{"userId": 7}',
        'a record with no user id and no flag': '{}',
        'a record with an empty user id': '{"userId": ""}',
      };

      corruptContents.forEach((name, contents) {
        test(name, () async {
          fileNamed('owner_record.json').writeAsStringSync(contents);

          expect(await service.read(), isA<OwnerRecordUnknown>());
        });
      });

      test('not valid text', () async {
        fileNamed('owner_record.json').writeAsBytesSync([0xff, 0xfe, 0xfd]);

        expect(await service.read(), isA<OwnerRecordUnknown>());
      });

      test('unreadable because the path is a folder', () async {
        Directory(p.join(directory.path, 'owner_record.json')).createSync();

        expect(await service.read(), isA<OwnerRecordUnknown>());
      });

      test('when the folder provider itself reports a missing path', () async {
        service = buildService(
          () => throw const PathNotFoundException('/app', OSError('gone', 2)),
        );

        expect(await service.read(), isA<OwnerRecordUnknown>());
      });

      test('in a folder that cannot be found', () async {
        service = buildService(() => throw Exception('no app folder'));

        expect(await service.read(), isA<OwnerRecordUnknown>());
      });
    });

    group('remove', () {
      test('makes the next read absent', () async {
        await service.write(userOne);

        await service.remove();

        expect(await service.read(), isA<OwnerRecordAbsent>());
      });

      test('also removes a leftover temporary file', () async {
        fileNamed('owner_record.json.tmp').writeAsStringSync('half');

        await service.remove();

        expect(fileNamed('owner_record.json.tmp').existsSync(), isFalse);
      });

      test('throws when the record path is a folder', () async {
        Directory(p.join(directory.path, 'owner_record.json')).createSync();

        await expectLater(service.remove(), throwsA(isA<IOException>()));
      });

      test('does nothing when there is no record', () async {
        await service.remove();

        expect(await service.read(), isA<OwnerRecordAbsent>());
      });
    });
  });
}
