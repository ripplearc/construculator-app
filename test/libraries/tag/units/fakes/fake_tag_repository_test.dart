import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/tag/domain/entities/tag_entity.dart';
import 'package:construculator/libraries/tag/testing/fake_tag_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeTagRepository', () {
    late FakeTagRepository repository;

    setUp(() {
      repository = FakeTagRepository();
    });

    test('getTags returns seeded tags', () async {
      repository.addTags(const [
        Tag(id: 'tag-1', name: 'Roofing'),
        Tag(id: 'tag-2', name: 'Plumbing'),
      ]);

      final result = await repository.getTags();

      result.fold((_) => fail('Expected Right but got Left'), (tags) {
        expect(tags.length, 2);
        expect(tags.first.name, 'Roofing');
      });
    });

    test('getTags returns configured failure', () async {
      repository.shouldFailOnGetTags = true;
      repository.getTagsFailure = UnexpectedFailure();

      final result = await repository.getTags();

      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('getTags records method calls', () async {
      await repository.getTags();
      await repository.getTags();

      expect(repository.getMethodCallsFor('getTags').length, 2);
    });

    test('reset clears tags, calls, and failure flags', () async {
      repository.addTags(const [Tag(id: 'tag-1', name: 'Roofing')]);
      repository.shouldFailOnGetTags = true;
      await repository.getTags();

      repository.reset();

      final result = await repository.getTags();
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (tags) => expect(tags, isEmpty),
      );
      expect(repository.getMethodCallsFor('getTags').length, 1);
    });
  });
}
